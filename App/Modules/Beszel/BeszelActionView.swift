import SwiftUI
import Foundation

/// Foreground Beszel agent using the upstream agent WebSocket protocol.
/// It must authenticate the hub's Ed25519 challenge before answering requests.
@MainActor
final class BeszelLiveAgent: ObservableObject {
    static let shared = BeszelLiveAgent()

    @Published private(set) var connected = false
    @Published private(set) var authenticated = false
    @Published private(set) var responses = 0
    @Published private(set) var status = "Отключён"

    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var receiver: Task<Void, Never>?
    private let metrics = IPhoneBeszelMetrics()

    private var token = ""
    private var name = "iPhone"
    private var hubKey = ""
    private var fingerprint = ""

    func start(hub: String, publicKey: String, token: String, deviceName: String) throws {
        guard !token.isEmpty, !token.contains("\n"), !token.contains("\r") else {
            throw ModuleOperationError("Укажи токен Beszel из панели.")
        }
        // Parse the public key before creating the socket. No unauthenticated fallback.
        _ = try BeszelHubIdentity.publicKey(from: publicKey)
        let url = try ModuleURL.secure(hub)
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ModuleOperationError("Неверный URL хаба.")
        }
        parts.scheme = "wss"
        let path = parts.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        parts.path = "/" + [path, "api/beszel/agent-connect"].filter { !$0.isEmpty }
            .joined(separator: "/")
        parts.query = nil
        parts.fragment = nil
        guard let wsURL = parts.url else { throw ModuleOperationError("Неверный WSS-адрес.") }
        stop()
        self.token = token
        self.hubKey = publicKey
        self.name = deviceName.isEmpty ? "iPhone" : deviceName
        self.fingerprint = IPhoneBeszelMetrics.persistentFingerprint()
        self.responses = 0

        var request = URLRequest(url: wsURL)
        request.timeoutInterval = 20
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.setValue("0.21.1", forHTTPHeaderField: "X-Beszel")

        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        let session = URLSession(configuration: config)
        self.session = session
        let socket = session.webSocketTask(with: request)
        self.socket = socket
        socket.resume()
        connected = true
        status = "Подключение к Beszel Hub..."
        receiver = Task { await receiveLoop(socket) }
    }

    func stop(reason: String = "Отключён") {
        receiver?.cancel()
        receiver = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        session?.invalidateAndCancel()
        session = nil
        connected = false
        authenticated = false
        status = reason
        token = ""
    }

    private func receiveLoop(_ socket: URLSessionWebSocketTask) async {
        do {
            while !Task.isCancelled, self.socket === socket {
                let message = try await socket.receive()
                guard !Task.isCancelled else { break }
                switch message {
                case .data(let data):
                    try await process(data, socket: socket)
                case .string:
                    // Beszel uses CBOR binary messages.
                    continue
                @unknown default:
                    continue
                }
            }
        } catch {
            if !Task.isCancelled, self.socket === socket {
                stop(reason: "Соединение завершено: \(error.localizedDescription)")
            }
        }
    }

    private func process(_ bytes: Data, socket: URLSessionWebSocketTask) async throws {
        guard bytes.count <= 1_048_576 else {
            throw ModuleOperationError("Получено слишком большое сообщение.")
        }
        let message = try BeszelWire.decode(bytes)
        guard let action = message.value(0)?.integer else {
            throw ModuleOperationError("Некорректный Beszel-запрос.")
        }
        let id = message.value(2)?.integer

        switch action {
        case 1: // CheckFingerprint: prove hub key before exposing any metrics
            let challenge = message.value(1)
            guard let signature = challenge?.value(0)?.byteData else {
                throw ModuleOperationError("Не получена подпись Beszel Hub.")
            }
            let key = try BeszelHubIdentity.publicKey(from: hubKey)
            guard key.isValidSignature(signature, for: Data(token.utf8)) else {
                throw ModuleOperationError("Подпись Beszel Hub не совпадает с KEY.")
            }
            authenticated = true
            let needInfo = challenge?.value(1)?.boolean ?? false
            var contents: [(UInt64, BeszelCBOR)] = [(0, .text(fingerprint))]
            if needInfo {
                contents.append((1, .text(name)))
                contents.append((2, .text(""))) // no SSH port in WSS-only mode
                contents.append((3, .text(name)))
            }
            let payload = BeszelCBOR.map(contents)
            var wrapper: [(UInt64, BeszelCBOR)] = [
                (2, payload), // legacy field
                (7, payload)  // generic response field
            ]
            if let id { wrapper.insert((0, .unsigned(id)), at: 0) }
            try await socket.send(.data(BeszelWire.encode(.map(wrapper))))
            status = "Beszel Hub подтверждён. Ожидание запросов статистики."

        case 0: // GetData. Beszel is request/response, not periodic blind POST.
            guard authenticated else {
                throw ModuleOperationError("Хаб ещё не прошёл проверку ключа.")
            }
            let withDetails = message.value(1)?.value(1)?.boolean ?? false
            let payload = metrics.snapshot(name: name, includeDetails: withDetails)
            var wrapper: [(UInt64, BeszelCBOR)] = [
                (1, payload), // legacy field
                (7, payload)  // generic response field
            ]
            if let id { wrapper.insert((0, .unsigned(id)), at: 0) }
            try await socket.send(.data(BeszelWire.encode(.map(wrapper))))
            responses += 1
            status = "Отправлено ответов со статистикой: \(responses)"

        default:
            // Unsupported actions (Docker logs, systemd, SMART) aren't available
            // to an ordinary iOS app. Return an explicit protocol error.
            guard authenticated else { return }
            var wrapper: [(UInt64, BeszelCBOR)] = [
                (3, .text("Action \(action) is unavailable on iOS"))
            ]
            if let id { wrapper.insert((0, .unsigned(id)), at: 0) }
            try await socket.send(.data(BeszelWire.encode(.map(wrapper))))
        }
    }
}

struct BeszelActionView: View {
    @Binding var values: [String: String]
    @ObservedObject private var agent = BeszelLiveAgent.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var registrationToken = ""
    @State private var publicKey = ""
    @State private var errorText = ""

    var body: some View {
        ModuleActionCard(title: "Агент iPhone → Beszel Hub", symbol: "iphone.gen3.radiowaves.left.and.right") {
            Text("iPhone сам подключается к твоему Beszel Hub по защищённому WebSocket. Он отвечает на запросы хаба показателями батареи, диска, памяти, CPU (если разрешено системой) и uptime.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ModuleField(title: "TOKEN (Beszel Hub, Keychain)",
                        placeholder: "Регистрационный токен",
                        value: $registrationToken, secure: true)
            ModuleField(title: "KEY (открытый ssh-ed25519 ключ хаба)",
                        placeholder: "ssh-ed25519 AAAA...",
                        value: $publicKey)

            ModuleResponse(value: agent.status, failed: !errorText.isEmpty)
            if !errorText.isEmpty { ModuleResponse(value: errorText, failed: true) }

            if agent.connected {
                HStack {
                    Circle()
                        .fill(agent.authenticated ? Palette.green : Palette.amber)
                        .frame(width: 9, height: 9)
                    Text(agent.authenticated ? "Хаб проверен" : "Проверка подлинности...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(agent.responses) ответов")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.secondary)
                }
                ModuleRunButton(title: "Отключить агента", symbol: "stop.fill") {
                    agent.stop()
                }
            } else {
                ModuleRunButton(title: "Подключить агента", symbol: "antenna.radiowaves.left.and.right") {
                    connect()
                }
            }

            Text("В панели Beszel добавь систему в режиме WebSocket и используй выданные KEY/TOKEN. Агент не работает в фоне: iOS приостанавливает приложение. Системные метрики, недоступные без специальных прав, не подделываются.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear {
            registrationToken = SecretVault.load("beszel-agent-token")
            publicKey = UserDefaults.standard.string(forKey: "aio.beszel.hubPublicKey") ?? ""
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { agent.stop(reason: "iOS: приложение неактивно, агент отключён.") }
        }
    }

    private func connect() {
        do {
            try agent.start(
                hub: values["url"] ?? "",
                publicKey: publicKey,
                token: registrationToken,
                deviceName: values["label"] ?? "iPhone"
            )
            guard SecretVault.save(registrationToken, account: "beszel-agent-token") else {
                agent.stop()
                throw ModuleOperationError("Не удалось сохранить TOKEN в Keychain.")
            }
            UserDefaults.standard.set(publicKey, forKey: "aio.beszel.hubPublicKey")
            errorText = ""
        } catch {
            errorText = error.localizedDescription
        }
    }
}
