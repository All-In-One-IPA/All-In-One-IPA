import Foundation
import Security

/// Credentials and API tokens never go into the module's UserDefaults configuration.
enum SecretVault {
    private static let service = "io.github.allinoneipa.credentials"

    static func load(_ account: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let bytes = item as? Data,
              let value = String(data: bytes, encoding: .utf8) else { return "" }
        return value
    }

    @discardableResult
    static func save(_ value: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        if value.isEmpty { return true }
        var insert = query
        insert[kSecValueData as String] = Data(value.utf8)
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }
}

struct ModuleOperationError: LocalizedError {
    let detail: String
    var errorDescription: String? { detail }

    init(_ detail: String) { self.detail = detail }
}

enum ModuleURL {
    /// Unencrypted remote credentials must not be sent over the network.
    static func secure(_ value: String) throws -> URL {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host != nil,
              url.user == nil, url.password == nil else {
            throw ModuleOperationError("Нужен корректный HTTPS-адрес без логина и пароля в URL.")
        }
        return url
    }

    static func endpoint(base: String, path: String) throws -> URL {
        let url = try secure(base)
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ModuleOperationError("Неверный URL.")
        }
        let components = path.split(separator: "?", maxSplits: 1,
                                    omittingEmptySubsequences: false)
        let suffix = String(components.first ?? "")
        parts.path = parts.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == ""
            ? suffix
            : "/" + parts.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + suffix
        parts.percentEncodedQuery = components.count > 1 ? String(components[1]) : nil
        parts.fragment = nil
        guard let final = parts.url else { throw ModuleOperationError("Не удалось собрать URL.") }
        return final
    }
}

enum ModuleHTTP {
    static func request(_ url: URL, method: String = "GET", body: Data? = nil,
                        contentType: String? = nil, token: String? = nil,
                        headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let token, !token.isEmpty {
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        }
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ModuleOperationError("Сервер вернул неизвестный тип ответа.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data.prefix(512), encoding: .utf8) ?? ""
            throw ModuleOperationError("HTTP \(http.statusCode): \(detail)")
        }
        return (data, http)
    }

    static func json(_ data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data)
    }
}
