import SwiftUI
import Network
import Darwin

private final class TCPConnectivityProbe {
    func check(host: String, port: UInt16) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(host),
                                          port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
            let started = Date()
            let queue = DispatchQueue(label: "io.github.allinoneipa.tcpprobe")
            var finished = false
            func complete(_ outcome: Result<Int, Error>) {
                guard !finished else { return }
                finished = true
                connection.cancel()
                continuation.resume(with: outcome)
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    complete(.success(Int(Date().timeIntervalSince(started) * 1000)))
                case .failed(let error):
                    complete(.failure(error))
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 8) {
                complete(.failure(ModuleOperationError("TCP-подключение не установлено за 8 секунд.")))
            }
        }
    }
}

private enum DNSLookup {
    static func lookup(_ name: String) throws -> [String] {
        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(name, nil, nil, &result)
        guard status == 0 else {
            throw ModuleOperationError("DNS: \(String(cString: gai_strerror(status)))")
        }
        defer { if let result { freeaddrinfo(result) } }
        var addresses: [String] = []
        var current = result
        while let node = current {
            var chars = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(node.pointee.ai_addr, socklen_t(node.pointee.ai_addrlen),
                           &chars, socklen_t(chars.count), nil, 0, NI_NUMERICHOST) == 0 {
                let address = String(cString: chars)
                if !addresses.contains(address) { addresses.append(address) }
            }
            current = node.pointee.ai_next
        }
        return addresses
    }
}

struct NetworkActionView: View {
    @Binding var values: [String: String]
    @State private var host = "example.com"
    @State private var port = "443"
    @State private var busy = false
    @State private var details = ""
    @State private var error = false

    var body: some View {
        VStack(spacing: 13) {
            HTTPDiagnosticView()
            ModuleActionCard(title: "DNS и TCP", symbol: "waveform.path.ecg") {
                ModuleField(title: "Домен или IP", placeholder: "example.com", value: $host)
                ModuleField(title: "TCP-порт", placeholder: "443", value: $port)

                ModuleRunButton(title: "Получить IP-адреса DNS", symbol: "globe", busy: busy) {
                    Task { await resolve() }
                }
                ModuleRunButton(title: "Проверить TCP-подключение", symbol: "point.3.connected.trianglepath.dotted",
                                busy: busy) {
                    Task { await connect() }
                }
                if !details.isEmpty { ModuleResponse(value: details, failed: error) }
            }
        }
    }

    @MainActor
    private func resolve() async {
        busy = true
        defer { busy = false }
        do {
            let target = host.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !target.isEmpty else { throw ModuleOperationError("Укажи домен.") }
            let ips = try await Task.detached(priority: .userInitiated) {
                try DNSLookup.lookup(target)
            }.value
            details = ips.isEmpty ? "DNS не вернул адресов." : ips.joined(separator: "\n")
            error = ips.isEmpty
        } catch {
            details = error.localizedDescription
            self.error = true
        }
    }

    @MainActor
    private func connect() async {
        busy = true
        defer { busy = false }
        do {
            guard let value = UInt16(port), value > 0, !host.isEmpty else {
                throw ModuleOperationError("Укажи адрес и порт 1–65535.")
            }
            let delay = try await TCPConnectivityProbe().check(host: host, port: value)
            details = "TCP-соединение установлено\n\(host):\(value) · \(delay) мс"
            error = false
        } catch {
            details = error.localizedDescription
            self.error = true
        }
    }
}
