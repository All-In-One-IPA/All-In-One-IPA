import SwiftUI

/// A working HTTP API client for services, Docker/Podman HTTPS gateways and custom APIs.
struct ServerActionView: View {
    @Binding var values: [String: String]
    @State private var path = "/"
    @State private var token = ""
    @State private var requestBody = "{}"
    @State private var response = ""
    @State private var busy = false
    @State private var failed = false

    var body: some View {
        ModuleActionCard(title: "HTTP API-клиент", symbol: "server.rack") {
            ModuleField(title: "Путь API", placeholder: "/api/status", value: $path)
            ModuleField(title: "Bearer-токен (Keychain)", placeholder: "Необязательно", value: $token, secure: true)
            HStack(spacing: 12) {
                Button("Сохранить токен") {
                    failed = !SecretVault.save(token, account: "server-\(values["name"] ?? "default")")
                    response = failed ? "Не удалось сохранить токен." : "Токен сохранён в Keychain."
                }
                Button("Удалить токен") {
                    token = ""
                    _ = SecretVault.save("", account: "server-\(values["name"] ?? "default")")
                    response = "Токен удалён."
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(Palette.cyan)

            if ["POST", "PUT", "PATCH"].contains(values["method"] ?? "GET") {
                Text("JSON тело запроса")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
                TextEditor(text: $requestBody)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 90)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
            }

            ModuleRunButton(title: "Выполнить HTTP-запрос", symbol: "arrow.up.right.circle", busy: busy) {
                Task { await execute() }
            }
            if !response.isEmpty { ModuleResponse(value: response, failed: failed) }
        }
        .onAppear {
            token = SecretVault.load("server-\(values["name"] ?? "default")")
        }
    }

    @MainActor
    private func execute() async {
        busy = true
        defer { busy = false }
        do {
            guard path.hasPrefix("/"), !path.hasPrefix("//") else {
                throw ModuleOperationError("Путь API должен начинаться с одного '/'.")
            }
            let base = values["endpoint"] ?? ""
            let url = try ModuleURL.endpoint(base: base, path: path)
            let method = values["method"] ?? "GET"
            var body: Data?
            if method == "POST" || method == "PUT" || method == "PATCH" {
                let raw = Data(requestBody.utf8)
                _ = try JSONSerialization.jsonObject(with: raw)
                body = raw
            }

            let started = Date()
            let (data, http) = try await ModuleHTTP.request(
                url, method: method, body: body,
                contentType: body == nil ? nil : "application/json",
                token: token
            )
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            var text = "HTTP \(http.statusCode) · \(ms) мс\n"
            if let json = ModuleHTTP.json(data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
               let string = String(data: pretty, encoding: .utf8) {
                text += String(string.prefix(12000))
            } else {
                text += String(decoding: data.prefix(12000), as: UTF8.self)
            }
            response = text
            failed = false
        } catch {
            response = error.localizedDescription
            failed = true
        }
    }
}
