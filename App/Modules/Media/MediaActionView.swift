import SwiftUI
import AVKit
import UniformTypeIdentifiers

private struct LibraryMedia: Identifiable {
    let url: URL
    var id: String { url.lastPathComponent }
}

/// Sandbox media collection, Files importer and native AVPlayer.
struct MediaActionView: View {
    @Binding var values: [String: String]
    @State private var files: [LibraryMedia] = []
    @State private var importing = false
    @State private var active: URL?
    @State private var player: AVPlayer?
    @State private var feedback: String?

    private var library: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AllInOneMedia", isDirectory: true)
    }

    var body: some View {
        ModuleActionCard(title: "Локальные медиа", symbol: "play.rectangle.on.rectangle") {
            ModuleRunButton(title: "Импортировать аудио или видео", symbol: "square.and.arrow.down") {
                importing = true
            }

            if let feedback { ModuleResponse(value: feedback) }

            if files.isEmpty {
                Text("Медиатека пуста. Выбери файл из приложения «Файлы».")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
            }
            ForEach(files) { file in
                HStack(spacing: 8) {
                    Button {
                        play(file.url)
                    } label: {
                        Label(file.url.lastPathComponent, systemImage: "play.circle.fill")
                            .font(.system(size: 12))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ShareLink(item: file.url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        delete(file.url)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .tint(Palette.cyan)
            }

            if let player {
                VideoPlayer(player: player)
                    .frame(height: 215)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                Button("Остановить воспроизведение") {
                    player.pause()
                    self.player = nil
                    active = nil
                }
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.audio, .movie, .video],
                      allowsMultipleSelection: true) { result in
            do {
                let urls = try result.get()
                try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)
                var imported = 0
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }
                    let cleanName = url.lastPathComponent.replacingOccurrences(of: "/", with: "_")
                    let dest = library.appendingPathComponent(UUID().uuidString + "-" + cleanName)
                    try FileManager.default.copyItem(at: url, to: dest)
                    imported += 1
                }
                refresh()
                feedback = "Импортировано: \(imported). Файлы хранятся в песочнице All-In-One."
            } catch { feedback = error.localizedDescription }
        }
        .onAppear(perform: refresh)
        .onDisappear {
            player?.pause()
        }
    }

    private func refresh() {
        files = ((try? FileManager.default.contentsOfDirectory(
            at: library, includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles])) ?? []).map { LibraryMedia(url: $0) }
            .sorted { $0.url.lastPathComponent < $1.url.lastPathComponent }
    }

    private func play(_ url: URL) {
        player?.pause()
        active = url
        player = AVPlayer(url: url)
        player?.play()
    }

    private func delete(_ url: URL) {
        if active == url {
            player?.pause()
            player = nil
            active = nil
        }
        do { try FileManager.default.removeItem(at: url) }
        catch { feedback = error.localizedDescription }
        refresh()
    }
}
