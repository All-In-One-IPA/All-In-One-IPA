import SwiftUI

private struct BeszelSystem: Identifiable {
    let id: String
    let name: String
    let status: String
    let host: String
}

struct BeszelActionView: View {
    @Binding var values: [String: String]
    @State private var identity = ""
    @State private var password = ""
    @State private var systems: [BeszelSystem] = []
    @State private var token = ""
    @State private var busy = false
    @State private var status = ""
    @State private var failed = false

    var body: some View {
        ModuleActionCard(title: "Панель Beszel", symbol: "chart.xyaxis.line") {
            Text("Прямое подключение к PocketBase API Beszel: авторизация и получение реального списка отслеживаемых систем.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
            ModuleField(title: "Email или имя пользователя", placeholder: "user@example.com", value: $identity)
            ModuleField(title: "Пароль Beszel", placeholder: "Пароль", value: $password, secure: true)
            ModuleRunButton(title: "Подключиться", symbol: "server.rack", busy: busy) {
                Task { await connect() }
            }
            if !token.isEmpty {
                ModuleRunButton(title: "Обновить системы", symbol: "arrow.clockwise", busy: busy) {
                    Task { await refresh() }
                }
            }

            ForEach(systems) { system in
                HStack {
                    Circle()
                        .fill(system.status == "up" ? Palette.green : Palette.coral)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(system.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        Text("\(system.host) · \(system.status)")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
            }
            if !status.isEmpty { ModuleResponse(value: status, failed: failed) }
        }
    }

    @MainActor
    private func connect() async {
        busy = true
        defer { busy = false }
        do {
            let url = try ModuleURL.endpoint(base: values["url"] ?? "",
                                             path: "/api/collections/users/auth-with-password")
            let data = try JSONSerialization.data(withJSONObject: [
                "identity": identity, "password": password
            ])
            let (reply, _) = try await ModuleHTTP.request(url, method: "POST",
                                                           body: data, contentType: "application/json")
            guard let json = ModuleHTTP.json(reply) as? [String: Any],
                  let newToken = json["token"] as? String else {
                throw ModuleOperationError("Не удалось получить токен Beszel.")
            }
            token = newToken
            password = ""
            await refresh()
        } catch {
            failed = true
            status = error.localizedDescription
        }
    }

    @MainActor
    private func refresh() async {
        busy = true
        defer { busy = false }
        do {
            guard !token.isEmpty else { throw ModuleOperationError("Сначала войди в Beszel.") }
            let url = try ModuleURL.endpoint(base: values["url"] ?? "",
                                             path: "/api/collections/systems/records?perPage=100")
            let (data, _) = try await ModuleHTTP.request(url, token: token)
            let json = ModuleHTTP.json(data) as? [String: Any]
            let records = json?["items"] as? [[String: Any]] ?? []
            systems = records.map { row in
                BeszelSystem(
                    id: row["id"] as? String ?? UUID().uuidString,
                    name: row["name"] as? String ?? "Система",
                    status: row["status"] as? String ?? "unknown",
                    host: row["host"] as? String ?? (row["hostname"] as? String ?? "")
                )
            }
            status = "Получены данные из Beszel: \(systems.count) систем."
            failed = false
        } catch {
            failed = true
            status = error.localizedDescription
        }
    }
}
