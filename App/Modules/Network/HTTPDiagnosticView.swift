import SwiftUI

/// The first real network diagnostic: explicit HTTPS HEAD request.
struct HTTPDiagnosticView: View {
    @State private var urlText = "https://example.com"
    @State private var busy = false
    @State private var result: String?
    @State private var success = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Palette.cyan)
                Text("HTTP-проверка")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("Доступно")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.green)
            }

            Text("Проверяет доступность HTTPS-сервера с помощью HEAD-запроса. Запускается только вручную.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField("https://example.com", text: $urlText)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14))
                .padding(13)
                .background(Palette.background, in: RoundedRectangle(cornerRadius: 13))

            Button {
                Task { await check() }
            } label: {
                HStack {
                    if busy { ProgressView().tint(Palette.background) }
                    else { Image(systemName: "arrow.up.right.circle.fill") }
                    Text(busy ? "Проверка..." : "Проверить HTTPS")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Palette.cyan, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(busy)

            if let result {
                Text(result)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(success ? Palette.green : Palette.coral)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .surfaceCard(radius: 22)
    }

    @MainActor
    private func check() async {
        let raw = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw), url.scheme?.lowercased() == "https",
              url.host != nil else {
            success = false
            result = "Нужен корректный HTTPS URL."
            return
        }

        busy = true
        result = nil
        defer { busy = false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            if let http = response as? HTTPURLResponse {
                success = (200..<500).contains(http.statusCode)
                result = "HTTP \(http.statusCode) · \(ms) мс\n\(http.url?.host ?? "сервер")"
            } else {
                success = true
                result = "Ответ получен · \(ms) мс"
            }
        } catch {
            success = false
            result = "Не удалось подключиться: \(error.localizedDescription)"
        }
    }
}
