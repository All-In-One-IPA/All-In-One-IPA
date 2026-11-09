import SwiftUI
import UniformTypeIdentifiers

/// Generates a usable, unsigned Apple DNS Settings configuration profile.
/// iOS requires explicit approval in Settings after the profile is shared/opened.
struct DNSActionView: View {
    @Binding var values: [String: String]
    @State private var profileURL: URL?
    @State private var feedback = ""

    var body: some View {
        ModuleActionCard(title: "DNS-профиль iOS", symbol: "network.badge.shield.half.filled") {
            Text("Создай настоящий .mobileconfig для DoH/DoT и установи его через настройки iOS.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ModuleRunButton(title: "Сформировать профиль", symbol: "doc.badge.gearshape") {
                do {
                    let content = try makeProfile()
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("All-In-One-DNS-\(UUID().uuidString.prefix(8)).mobileconfig")
                    try content.write(to: url, options: .atomic)
                    profileURL = url
                    feedback = "Профиль готов. Поделись файлом с приложением «Файлы» и открой его для установки."
                } catch {
                    profileURL = nil
                    feedback = error.localizedDescription
                }
            }

            if let profileURL {
                ShareLink(item: profileURL) {
                    Label("Сохранить или поделиться .mobileconfig", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Palette.cyan)
            }
            if !feedback.isEmpty { ModuleResponse(value: feedback) }
        }
    }

    private func makeProfile() throws -> Data {
        let name = (values["display"] ?? "All-In-One DNS")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw ModuleOperationError("Укажи название профиля.") }
        let mode = values["mode"] ?? "DoH"

        var settings: [String: Any] = [:]
        if mode == "DoH" {
            let url = try ModuleURL.secure(values["endpoint"] ?? "")
            settings = ["DNSProtocol": "HTTPS", "ServerURL": url.absoluteString]
        } else if mode == "DoT" {
            let host = (values["serverName"] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !host.isEmpty, !host.contains(" "), !host.contains("://"),
                  host.count < 254 else { throw ModuleOperationError("Неверное доменное имя DoT-сервера.") }
            settings = ["DNSProtocol": "TLS", "ServerName": host]
        } else {
            throw ModuleOperationError("Неподдерживаемый DNS-режим.")
        }

        let id = UUID().uuidString
        let payload: [String: Any] = [
            "PayloadType": "com.apple.dnsSettings.managed",
            "PayloadVersion": 1,
            "PayloadIdentifier": "io.github.allinoneipa.dns.\(id)",
            "PayloadUUID": UUID().uuidString,
            "PayloadDisplayName": name,
            "DNSSettings": settings
        ]
        let profile: [String: Any] = [
            "PayloadType": "Configuration",
            "PayloadVersion": 1,
            "PayloadIdentifier": "io.github.allinoneipa.profile.\(id)",
            "PayloadUUID": id,
            "PayloadDisplayName": name,
            "PayloadDescription": "DNS profile created locally by All-In-One.",
            "PayloadOrganization": "All-In-One",
            "PayloadRemovalDisallowed": false,
            "PayloadContent": [payload]
        ]
        return try PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0)
    }
}
