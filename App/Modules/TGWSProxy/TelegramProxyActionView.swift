import SwiftUI
import Network
import Darwin

/// A foreground-only local SOCKS5/TCP relay. This is a genuine network
/// operation, but is NOT yet Flowseal's MTProto-over-WebSocket transport.
private final class SOCKS5Session {
    private enum Phase { case greeting, request, connecting, relay }
    private let client: NWConnection
    private let queue: DispatchQueue
    private let finished: () -> Void
    private var remote: NWConnection?
    private var phase: Phase = .greeting
    private var buffer = Data()
    private var stopped = false

    init(client: NWConnection, queue: DispatchQueue, finished: @escaping () -> Void) {
        self.client = client
        self.queue = queue
        self.finished = finished
        client.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.stop() }
        }
        client.start(queue: queue)
        readHandshake()
    }

    func stop() {
        guard !stopped else { return }
        stopped = true
        client.cancel()
        remote?.cancel()
        finished()
    }

    private func sendClient(_ bytes: [UInt8]) {
        client.send(content: Data(bytes), completion: .contentProcessed { [weak self] error in
            if error != nil { self?.stop() }
        })
    }

    private func readHandshake() {
        guard !stopped, phase != .relay else { return }
        client.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, done, error in
            guard let self else { return }
            if let data { self.buffer.append(data) }
            if self.buffer.count > 65536 || done || error != nil { self.stop(); return }
            self.parseHandshake()
            if !self.stopped, self.phase != .relay && self.phase != .connecting {
                self.readHandshake()
            }
        }
    }

    private func parseHandshake() {
        let bytes = [UInt8](buffer)
        switch phase {
        case .greeting:
            guard bytes.count >= 2 else { return }
            guard bytes[0] == 5, bytes.count >= 2 + Int(bytes[1]) else {
                if bytes[0] != 5 { stop() }
                return
            }
            let accepted = bytes.dropFirst(2).prefix(Int(bytes[1])).contains(UInt8(0))
            buffer.removeFirst(2 + Int(bytes[1]))
            sendClient([5, accepted ? 0 : 255])
            if accepted {
                phase = .request
                parseHandshake()
            } else {
                stop()
            }
        case .request:
            guard bytes.count >= 4 else { return }
            guard bytes[0] == 5, bytes[1] == 1, bytes[2] == 0 else {
                sendClient([5, 7, 0, 1, 0, 0, 0, 0, 0, 0])
                stop()
                return
            }

            let host: String
            let requestLength: Int
            let portOffset: Int
            switch bytes[3] {
            case 1:
                guard bytes.count >= 10 else { return }
                host = bytes[4..<8].map { String($0) }.joined(separator: ".")
                portOffset = 8
                requestLength = 10
            case 4: // IPv6 destination requested by Telegram
                guard bytes.count >= 22 else { return }
                var address = in6_addr()
                withUnsafeMutableBytes(of: &address) { dest in
                    dest.copyBytes(from: bytes[4..<20])
                }
                var printable = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                let converted = withUnsafePointer(to: &address) {
                    inet_ntop(AF_INET6, $0, &printable, socklen_t(printable.count))
                }
                guard converted != nil else { stop(); return }
                host = String(cString: printable)
                portOffset = 20
                requestLength = 22
            case 3:
                guard bytes.count >= 5 else { return }
                let length = Int(bytes[4])
                guard length > 0, bytes.count >= 5 + length + 2 else { return }
                host = String(decoding: bytes[5..<(5 + length)], as: UTF8.self)
                portOffset = 5 + length
                requestLength = 5 + length + 2
            default:
                sendClient([5, 8, 0, 1, 0, 0, 0, 0, 0, 0])
                stop()
                return
            }
            let port = UInt16(bytes[portOffset]) << 8 | UInt16(bytes[portOffset + 1])
            guard let endpointPort = NWEndpoint.Port(rawValue: port), port > 0 else {
                stop()
                return
            }
            buffer.removeFirst(requestLength)
            phase = .connecting
            let upstream = NWConnection(host: NWEndpoint.Host(host), port: endpointPort, using: .tcp)
            remote = upstream
            upstream.stateUpdateHandler = { [weak self] state in
                guard let self, !self.stopped else { return }
                switch state {
                case .ready:
                    self.sendClient([5, 0, 0, 1, 0, 0, 0, 0, 0, 0])
                    self.phase = .relay
                    if !self.buffer.isEmpty {
                        upstream.send(content: self.buffer, completion: .contentProcessed { error in
                            if error != nil { self.stop() }
                        })
                        self.buffer.removeAll()
                    }
                    self.pump(self.client, to: upstream)
                    self.pump(upstream, to: self.client)
                case .failed:
                    self.sendClient([5, 5, 0, 1, 0, 0, 0, 0, 0, 0])
                    self.stop()
                default: break
                }
            }
            upstream.start(queue: queue)
        case .connecting, .relay:
            return
        }
    }

    private func pump(_ incoming: NWConnection, to outgoing: NWConnection) {
        guard !stopped else { return }
        incoming.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, done, error in
            guard let self, !self.stopped else { return }
            if let data, !data.isEmpty {
                outgoing.send(content: data, completion: .contentProcessed { sendError in
                    if sendError != nil { self.stop() }
                    else { self.pump(incoming, to: outgoing) }
                })
            } else if done || error != nil {
                self.stop()
            } else {
                self.pump(incoming, to: outgoing)
            }
        }
    }
}

private final class LocalSOCKS5Proxy: ObservableObject {
    /// A shared service is not destroyed when SwiftUI rebuilds a tab or workspace.
    static let shared = LocalSOCKS5Proxy()
    @Published private(set) var running = false
    @Published private(set) var status = "Остановлен"
    @Published private(set) var sessions = 0
    @Published private(set) var activePort: UInt16?

    private let queue = DispatchQueue(label: "io.github.allinoneipa.socks5")
    private var listener: NWListener?
    private var connections: [UUID: SOCKS5Session] = [:]

    func start(port: UInt16) {
        guard !running, listener == nil else { return }
        status = "Запуск локального SOCKS5..."
        guard let endpointPort = NWEndpoint.Port(rawValue: port), port > 0 else {
            status = "Укажи порт от 1 до 65535."
            return
        }
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            params.requiredLocalEndpoint = .hostPort(host: NWEndpoint.Host("127.0.0.1"), port: endpointPort)
            let listener = try NWListener(using: params)
            listener.newConnectionHandler = { [weak self] connection in
                guard let self else { connection.cancel(); return }
                let identifier = UUID()
                self.connections[identifier] = SOCKS5Session(
                    client: connection, queue: self.queue,
                    finished: { [weak self] in
                        guard let self else { return }
                        self.connections.removeValue(forKey: identifier)
                        let count = self.connections.count
                        Task { @MainActor in self.sessions = count }
                    }
                )
                let count = self.connections.count
                Task { @MainActor in self.sessions = count }
            }
            listener.stateUpdateHandler = { [weak self, weak listener] state in
                Task { @MainActor [weak self, weak listener] in
                    guard let self, let listener, self.listener === listener else { return }
                    switch state {
                    case .ready:
                        self.running = true
                        self.activePort = port
                        self.status = "SOCKS5 слушает 127.0.0.1:\(port)"
                    case .waiting(let error):
                        self.status = "Ожидание сетевого интерфейса: \(error.localizedDescription)"
                    case .failed(let error):
                        self.stop(reason: "Не удалось запустить SOCKS5: \(error.localizedDescription)")
                    case .cancelled:
                        self.stop(reason: "Слушатель был отменён системой.")
                    default: break
                    }
                }
            }
            self.listener = listener
            listener.start(queue: queue)
            status = "Запуск сервера..."
        } catch {
            status = error.localizedDescription
        }
    }

    func stop(reason: String = "Остановлен вручную") {
        let old = listener
        listener = nil
        old?.cancel()
        queue.async {
            let active = Array(self.connections.values)
            self.connections.removeAll()
            for session in active { session.stop() }
        }
        running = false
        sessions = 0
        activePort = nil
        status = reason
    }

    /// Test the listener with a real SOCKS5 no-auth greeting on loopback.
    func selfTest() async throws -> String {
        guard running, let port = activePort,
              let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw ModuleOperationError("Сначала запусти SOCKS5-сервер.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "io.github.allinoneipa.socks5.selftest")
            let probe = NWConnection(host: "127.0.0.1", port: endpointPort, using: .tcp)
            var finished = false
            func complete(_ result: Result<String, Error>) {
                guard !finished else { return }
                finished = true
                probe.cancel()
                continuation.resume(with: result)
            }
            probe.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    probe.send(content: Data([5, 1, 0]), completion: .contentProcessed { error in
                        if let error { complete(.failure(error)); return }
                        probe.receive(minimumIncompleteLength: 2, maximumLength: 2) {
                            data, _, _, error in
                            if let error { complete(.failure(error)); return }
                            guard data == Data([5, 0]) else {
                                complete(.failure(ModuleOperationError(
                                    "Сервер не ответил на SOCKS5-приветствие."
                                )))
                                return
                            }
                            complete(.success("Проверка пройдена: порт \(port) отвечает по SOCKS5."))
                        }
                    })
                case .failed(let error):
                    complete(.failure(error))
                default: break
                }
            }
            probe.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 6) {
                complete(.failure(ModuleOperationError("Тайм-аут проверки SOCKS5 (6 секунд).")))
            }
        }
    }
}

struct TelegramProxyActionView: View {
    @Binding var values: [String: String]
    @ObservedObject private var relay = LocalSOCKS5Proxy.shared
    @State private var testResult = ""

    var body: some View {
        ModuleActionCard(title: "Локальный SOCKS5-транспорт", symbol: "network") {
            Text("Рабочий TCP-релей без авторизации, привязанный к 127.0.0.1. Он действует только пока iOS позволяет приложению работать. Это пока НЕ MTProto-over-WebSocket из Flowseal/tg-ws-proxy.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ModuleResponse(value: relay.status + "\nАктивных подключений: \(relay.sessions)")
            if relay.running {
                ModuleRunButton(title: "Проверить локальный порт", symbol: "checkmark.shield") {
                    Task {
                        do { testResult = try await relay.selfTest() }
                        catch { testResult = "Проверка: \(error.localizedDescription)" }
                    }
                }
                if !testResult.isEmpty { ModuleResponse(value: testResult) }
                ModuleRunButton(title: "Остановить SOCKS5", symbol: "stop.fill") {
                    relay.stop()
                }
                if let port = UInt16(values["listenPort"] ?? "1080"),
                   let url = URL(string: "tg://socks?server=127.0.0.1&port=\(port)") {
                    Link(destination: url) {
                        Label("Передать настройки прокси в Telegram", systemImage: "paperplane.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.cyan)
                    }
                }
            } else {
                ModuleRunButton(title: "Запустить локальный SOCKS5", symbol: "play.fill") {
                    relay.start(port: UInt16(values["listenPort"] ?? "1080") ?? 0)
                }
            }
            Text("При переходе в Telegram iOS может приостановить приложение и оборвать соединение. Постоянная работа в фоне требует отдельного исследования системных механизмов.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
