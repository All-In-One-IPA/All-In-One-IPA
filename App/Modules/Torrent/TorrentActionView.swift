import SwiftUI
import UniformTypeIdentifiers

struct LocalTorrent: Identifiable {
    let id: Int
    let name: String
    let progress: Double
    let downloaded: Int64
    let total: Int64
    let uploaded: Int64
    let state: String
    let downloadSpeed: Double
    let uploadSpeed: Double

    init?(json: [String: Any]) {
        guard let id = json["id"] as? Int else { return nil }
        self.id = id
        self.name = (json["name"] as? String) ?? (json["info_hash"] as? String) ?? "Torrent \(id)"
        let stats = json["stats"] as? [String: Any] ?? [:]
        downloaded = (stats["progress_bytes"] as? NSNumber)?.int64Value ?? 0
        total = (stats["total_bytes"] as? NSNumber)?.int64Value ?? 0
        uploaded = (stats["uploaded_bytes"] as? NSNumber)?.int64Value ?? 0
        progress = total > 0 ? min(1, max(0, Double(downloaded) / Double(total))) : 0
        state = stats["state"] as? String ?? "metadata"
        let live = stats["live"] as? [String: Any] ?? [:]
        downloadSpeed = ((live["download_speed"] as? [String: Any])?["mbps"] as? NSNumber)?.doubleValue ?? 0
        uploadSpeed = ((live["upload_speed"] as? [String: Any])?["mbps"] as? NSNumber)?.doubleValue ?? 0
    }
}

private struct TorrentExecution<Value>: @unchecked Sendable {
    let result: Value
}

@MainActor
final class LocalTorrentEngine: ObservableObject {
    static let shared = LocalTorrentEngine()

    @Published private(set) var running = false
    @Published private(set) var busy = false
    @Published private(set) var torrents: [LocalTorrent] = []
    @Published private(set) var status = "Движок остановлен"

    private var downloadFolder: String?

    private func execute<T>(_ action: @escaping @Sendable () throws -> T) async throws -> T {
        let wrapped = try await Task.detached(priority: .userInitiated) {
            TorrentExecution(result: try action())
        }.value
        return wrapped.result
    }

    func start(folder: String) async {
        guard !running, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let folderName = folder.range(of: "^[A-Za-z0-9_-]{1,40}$",
                                           options: .regularExpression) != nil ? folder : "Torrents"
            let folderURL = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            )[0].appendingPathComponent(folderName, isDirectory: true)
            try FileManager.default.createDirectory(
                at: folderURL, withIntermediateDirectories: true
            )
            let path = folderURL.path
            _ = try await execute { try EmbeddedTorrentLibrary.start(at: path) }
            downloadFolder = path
            running = true
            status = "librqbit 9.0.0 · локальный движок запущен"
            await refresh()
        } catch {
            status = "Ошибка запуска: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        guard running else { return }
        do {
            let response = try await execute { try EmbeddedTorrentLibrary.list() }
            let data = response["torrents"] as? [[String: Any]] ?? []
            torrents = data.compactMap(LocalTorrent.init)
        } catch {
            status = "Не удалось обновить список: \(error.localizedDescription)"
        }
    }

    func addMagnet(_ text: String) async {
        guard running, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            _ = try await execute { try EmbeddedTorrentLibrary.magnet(text) }
            status = "Magnet добавлен в локальную очередь."
            await refresh()
        } catch { status = "Ошибка magnet: \(error.localizedDescription)" }
    }

    func addTorrent(fileAt path: String) async {
        guard running, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            _ = try await execute { try EmbeddedTorrentLibrary.torrentFile(at: path) }
            status = "Torrent добавлен в локальную очередь."
            await refresh()
        } catch { status = "Ошибка .torrent: \(error.localizedDescription)" }
    }

    func control(id: Int, action: TorrentControl) async {
        guard running, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await execute {
                switch action {
                case .pause: try EmbeddedTorrentLibrary.pause(id)
                case .resume: try EmbeddedTorrentLibrary.resume(id)
                case .forget: try EmbeddedTorrentLibrary.remove(id, files: false)
                case .delete: try EmbeddedTorrentLibrary.remove(id, files: true)
                }
            }
            status = "Действие выполнено."
            await refresh()
        } catch { status = "Ошибка управления: \(error.localizedDescription)" }
    }

    func stop() async {
        guard running else { return }
        running = false
        do {
            try await execute { try EmbeddedTorrentLibrary.shutdown() }
        } catch { status = "Ошибка остановки: \(error.localizedDescription)" }
        torrents = []
        downloadFolder = nil
        status = "Движок остановлен. При следующем запуске очередь восстановится."
    }
}

enum TorrentControl: Sendable {
    case pause, resume, forget, delete
}

/// Everything here runs on the phone: the Rust static library opens peers,
/// fetches pieces and writes into Documents, no qBittorrent HTTP endpoints.
struct TorrentActionView: View {
    @Binding var values: [String: String]
    @ObservedObject private var engine = LocalTorrentEngine.shared
    @State private var magnet = ""
    @State private var importingTorrent = false
    @State private var selectedForRemoval: Int?
    @State private var showingRemove = false

    private var downloadFolderName: String {
        values["downloadFolder"] ?? "Torrents"
    }

    var body: some View {
        ModuleActionCard(title: "Локальный BitTorrent", symbol: "arrow.down.to.line.compact") {
            Text("librqbit работает непосредственно на iPhone. Поддерживаются magnet, .torrent, DHT, пиры и сохранение в «На моём iPhone». Никакого qBittorrent и отдельного сервера.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 9) {
                Circle()
                    .fill(engine.running ? Palette.green : Palette.amber)
                    .frame(width: 9, height: 9)
                Text(engine.running ? "Движок работает" : "Движок остановлен")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(engine.torrents.count) задач")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Palette.secondary)
            }

            ModuleResponse(value: engine.status)

            if engine.running {
                ModuleField(title: "Magnet-ссылка", placeholder: "magnet:?xt=urn:btih:...", value: $magnet)
                ModuleRunButton(title: "Добавить magnet", symbol: "plus", busy: engine.busy) {
                    Task { await engine.addMagnet(magnet) }
                }
                ModuleRunButton(title: "Открыть .torrent файл", symbol: "doc", busy: engine.busy) {
                    importingTorrent = true
                }
                ModuleRunButton(title: "Обновить состояние", symbol: "arrow.clockwise", busy: engine.busy) {
                    Task { await engine.refresh() }
                }
                ModuleRunButton(title: "Остановить движок", symbol: "stop.fill", busy: engine.busy) {
                    Task { await engine.stop() }
                }

                if engine.torrents.isEmpty {
                    Text("Очередь пуста. Добавь magnet или выбери .torrent из «Файлы».")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.secondary)
                }
                ForEach(engine.torrents) { item in
                    torrentCard(item)
                }
            } else {
                ModuleRunButton(title: "Запустить librqbit", busy: engine.busy) {
                    Task { await engine.start(folder: downloadFolderName) }
                }
            }

            Text("iOS может остановить сетевую сессию после сворачивания. При возвращении в приложение очередь восстанавливается из локального состояния.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fileImporter(isPresented: $importingTorrent, allowedContentTypes: [
            UTType(filenameExtension: "torrent") ?? .data
        ]) { result in
            do {
                let fileURL = try result.get()
                guard fileURL.startAccessingSecurityScopedResource() else {
                    throw ModuleOperationError("Не удалось получить доступ к .torrent.")
                }
                let temporary = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".torrent")
                defer { fileURL.stopAccessingSecurityScopedResource() }
                try FileManager.default.copyItem(at: fileURL, to: temporary)
                Task {
                    await engine.addTorrent(fileAt: temporary.path)
                    try? FileManager.default.removeItem(at: temporary)
                }
            } catch {
                // Import errors are informational; no files are removed.
                print("Torrent import: \(error.localizedDescription)")
            }
        }
        .confirmationDialog("Удалить торрент?", isPresented: $showingRemove) {
            if let id = selectedForRemoval {
                Button("Удалить из очереди, сохранить файлы") {
                    Task { await engine.control(id: id, action: .forget) }
                }
                Button("Удалить торрент вместе с файлами", role: .destructive) {
                    Task { await engine.control(id: id, action: .delete) }
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .task {
            if !engine.running {
                await engine.start(folder: downloadFolderName)
            }
            while !Task.isCancelled {
                if engine.running { await engine.refresh() }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    private func torrentCard(_ torrent: LocalTorrent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(torrent.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                Spacer()
                Menu {
                    Button("Пауза", systemImage: "pause") {
                        Task { await engine.control(id: torrent.id, action: .pause) }
                    }
                    Button("Продолжить", systemImage: "play") {
                        Task { await engine.control(id: torrent.id, action: .resume) }
                    }
                    Button("Удалить", systemImage: "trash", role: .destructive) {
                        selectedForRemoval = torrent.id
                        showingRemove = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Palette.cyan)
                }
            }

            ProgressView(value: torrent.progress)
                .tint(Palette.cyan)

            HStack {
                Text("\(Int(torrent.progress * 100))% · \(torrent.state)")
                Spacer()
                Text("\(format(torrent.downloaded)) / \(format(torrent.total))")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Palette.secondary)

            HStack {
                Label(String(format: "%.2f MiB/s", torrent.downloadSpeed), systemImage: "arrow.down")
                Spacer()
                Label(String(format: "%.2f MiB/s", torrent.uploadSpeed), systemImage: "arrow.up")
            }
            .font(.system(size: 11))
            .foregroundStyle(Palette.secondary)
        }
        .padding(13)
        .background(Palette.background, in: RoundedRectangle(cornerRadius: 15))
    }

    private func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
