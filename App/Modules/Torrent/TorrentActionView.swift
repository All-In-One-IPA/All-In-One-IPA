import SwiftUI

@MainActor
private final class TorrentConnection: ObservableObject {
    let session: URLSession
    @Published var torrents: [[String: Any]] = []

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        session = URLSession(configuration: config)
    }

    func signIn(base: String, username: String, password: String) async throws {
        let url = try ModuleURL.endpoint(base: base, path: "/api/v2/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("\(url.scheme!)://\(url.host!)", forHTTPHeaderField: "Origin")
        request.setValue(url.deletingLastPathComponent().absoluteString, forHTTPHeaderField: "Referer")
        request.httpBody = form(["username": username, "password": password])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) == "Ok." else {
            throw ModuleOperationError("qBittorrent отклонил авторизацию.")
        }
    }

    func refresh(base: String) async throws {
        let url = try ModuleURL.endpoint(base: base, path: "/api/v2/torrents/info")
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ModuleOperationError("Не удалось получить список торрентов. Авторизуйся заново.")
        }
        torrents = (try JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
    }

    func addMagnet(base: String, magnet: String) async throws {
        guard magnet.hasPrefix("magnet:?xt=urn:btih:") || magnet.hasPrefix("magnet:?xt=urn:btmh:") else {
            throw ModuleOperationError("Требуется корректная magnet-ссылка.")
        }
        let url = try ModuleURL.endpoint(base: base, path: "/api/v2/torrents/add")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("\(url.scheme!)://\(url.host!)", forHTTPHeaderField: "Origin")
        request.setValue(url.deletingLastPathComponent().absoluteString, forHTTPHeaderField: "Referer")
        request.httpBody = form(["urls": magnet])
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              String(decoding: data, as: UTF8.self).contains("Ok") else {
            throw ModuleOperationError("qBittorrent не принял magnet-ссылку.")
        }
    }

    private func form(_ dictionary: [String: String]) -> Data {
        let items = dictionary.map { key, value in
            let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
            let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            return "\(key)=\(encoded)"
        }
        return Data(items.joined(separator: "&").utf8)
    }
}

struct TorrentActionView: View {
    @Binding var values: [String: String]
    @StateObject private var client = TorrentConnection()
    @State private var username = ""
    @State private var password = ""
    @State private var magnet = ""
    @State private var busy = false
    @State private var status = ""
    @State private var failed = false
    @State private var signedIn = false

    var body: some View {
        ModuleActionCard(title: "Удалённый qBittorrent", symbol: "arrow.down.circle.fill") {
            Text("Подключение к настоящему qBittorrent Web API через HTTPS. Торренты загружаются на удалённом сервере, не на iPhone.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ModuleField(title: "Имя пользователя qBittorrent", placeholder: "admin", value: $username)
            ModuleField(title: "Пароль (только в памяти)", placeholder: "Пароль", value: $password, secure: true)
            ModuleRunButton(title: "Войти и загрузить очередь", symbol: "person.crop.circle", busy: busy) {
                Task {
                    await work {
                        try await client.signIn(base: values["url"] ?? "", username: username, password: password)
                        signedIn = true
                        try await client.refresh(base: values["url"] ?? "")
                        return "Подключено. Торрентов: \(client.torrents.count)."
                    }
                }
            }

            if signedIn {
                ModuleField(title: "Magnet", placeholder: "magnet:?xt=...", value: $magnet)
                ModuleRunButton(title: "Добавить magnet", symbol: "plus.circle", busy: busy) {
                    Task {
                        await work {
                            try await client.addMagnet(base: values["url"] ?? "", magnet: magnet)
                            try await client.refresh(base: values["url"] ?? "")
                            return "Magnet отправлен в qBittorrent."
                        }
                    }
                }
                ModuleRunButton(title: "Обновить очередь", symbol: "arrow.clockwise", busy: busy) {
                    Task {
                        await work {
                            try await client.refresh(base: values["url"] ?? "")
                            return "Очередь обновлена."
                        }
                    }
                }

                ForEach(Array(client.torrents.prefix(40).enumerated()), id: \.offset) { _, torrent in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(torrent["name"] as? String ?? "Без названия")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(2)
                        let progress = min(max((torrent["progress"] as? Double ?? 0), 0), 1)
                        ProgressView(value: progress)
                            .tint(Palette.cyan)
                        Text("\(Int(progress * 100))% · \(torrent["state"] as? String ?? "unknown")")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.secondary)
                    }
                }
            }
            if !status.isEmpty { ModuleResponse(value: status, failed: failed) }
        }
    }

    @MainActor
    private func work(_ action: () async throws -> String) async {
        busy = true
        defer { busy = false }
        do { status = try await action(); failed = false }
        catch { status = error.localizedDescription; failed = true }
    }
}
