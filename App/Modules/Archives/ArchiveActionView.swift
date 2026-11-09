import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

private struct StoredArchive: Identifiable {
    let url: URL
    var id: String { url.lastPathComponent }
}

/// File import, ZIP extraction, ZIP creation and Files export.
struct ArchiveActionView: View {
    @Binding var values: [String: String]
    @State private var importing = false
    @State private var creatingZIP = false
    @State private var entries: [StoredArchive] = []
    @State private var extracted: [StoredArchive] = []
    @State private var info = ""

    private var root: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AllInOneArchives", isDirectory: true)
    }

    var body: some View {
        ModuleActionCard(title: "Архиватор ZIP", symbol: "doc.zipper") {
            ModuleRunButton(title: "Открыть ZIP из «Файлы»", symbol: "archivebox") {
                importing = true
            }
            ModuleRunButton(title: "Сжать файл в ZIP", symbol: "square.and.arrow.down") {
                creatingZIP = true
            }
            if !info.isEmpty { ModuleResponse(value: info) }

            ForEach(entries) { entry in
                HStack(spacing: 8) {
                    Text(entry.url.lastPathComponent)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Spacer()
                    Button("Распаковать") { unpack(entry.url) }
                        .font(.system(size: 12, weight: .medium))
                    ShareLink(item: entry.url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            if !extracted.isEmpty {
                Text("Распакованные элементы")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                ForEach(extracted) { entry in
                    HStack {
                        Text(entry.url.lastPathComponent)
                            .font(.system(size: 12))
                        Spacer()
                        ShareLink(item: entry.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.zip]) { result in
            do {
                let url = try result.get()
                try importArchive(url)
            } catch { info = error.localizedDescription }
        }
        .fileImporter(isPresented: $creatingZIP, allowedContentTypes: [.item]) { result in
            do {
                let url = try result.get()
                try createArchive(of: url)
            } catch { info = error.localizedDescription }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        entries = contents.filter { $0.pathExtension.lowercased() == "zip" }
            .map { StoredArchive(url: $0) }
            .sorted { $0.id < $1.id }
        extracted = contents.filter {
            $0.pathExtension.lowercased() != "zip"
        }.map { StoredArchive(url: $0) }
    }

    private func importArchive(_ url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ModuleOperationError("Нет доступа к выбранному файлу.")
        }
        defer { url.stopAccessingSecurityScopedResource() }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let destination = root.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: destination)
        refresh()
        info = "Архив добавлен. Нажми «Распаковать»."
    }

    private func unpack(_ url: URL) {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            var count = 0
            var total: UInt64 = 0
            for entry in archive {
                let components = entry.path.split(separator: "/")
                guard !entry.path.hasPrefix("/"), !components.contains(".."),
                      entry.type != .symlink else {
                    throw ModuleOperationError("В ZIP обнаружен небезопасный путь.")
                }
                count += 1
                total += UInt64(entry.uncompressedSize)
                guard count <= 3000, total <= 1_000_000_000 else {
                    throw ModuleOperationError("Архив превышает безопасные ограничения.")
                }
            }

            let folder = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            do {
                try FileManager.default.unzipItem(at: url, to: folder)
            } catch {
                try? FileManager.default.removeItem(at: folder)
                throw error
            }
            info = "Распаковано файлов: \(count)."
            refresh()
        } catch { info = error.localizedDescription }
    }

    private func createArchive(of url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ModuleOperationError("Нет доступа к выбранному файлу.")
        }
        defer { url.stopAccessingSecurityScopedResource() }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".zip"
        let result = root.appendingPathComponent(name)
        try FileManager.default.zipItem(at: url, to: result)
        refresh()
        info = "Создан ZIP: \(name)"
    }
}
