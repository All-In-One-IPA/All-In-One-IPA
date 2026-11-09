import SwiftUI
import UIKit

private struct SavedAction: Identifiable, Codable {
    var id = UUID()
    var title: String
    var kind: String
    var content: String
}

/// Local, runnable actions. Does not claim to be a background scheduler.
struct AutomationActionView: View {
    @Binding var values: [String: String]
    @State private var title = ""
    @State private var kind = "Открыть сайт"
    @State private var content = ""
    @State private var items: [SavedAction] = []
    @State private var history = ""
    @State private var busy = false
    @State private var error = false

    private let choices = ["Открыть сайт", "Скопировать текст", "Проверить HTTPS"]

    var body: some View {
        ModuleActionCard(title: "Быстрые действия", symbol: "bolt.fill") {
            Text("Создавай и запускай реальные действия вручную. Они хранятся локально; автоматическое фоновое выполнение пока не включено.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ModuleField(title: "Название", placeholder: "Моё действие", value: $title)
            Picker("Тип действия", selection: $kind) {
                ForEach(choices, id: \.self) { value in Text(value).tag(value) }
            }
            .pickerStyle(.menu)
            .tint(Palette.cyan)
            ModuleField(title: kind == "Скопировать текст" ? "Текст" : "HTTPS URL",
                        placeholder: kind == "Скопировать текст" ? "Текст для копирования" : "https://example.com",
                        value: $content)
            ModuleRunButton(title: "Сохранить действие", symbol: "plus") {
                let item = SavedAction(title: title.trimmingCharacters(in: .whitespaces),
                                       kind: kind, content: content)
                guard !item.title.isEmpty, !item.content.isEmpty else {
                    history = "Укажи название и содержимое."
                    error = true
                    return
                }
                items.append(item)
                save()
                title = ""
                content = ""
                history = "Действие добавлено."
                error = false
            }

            ForEach(items) { item in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        Text(item.kind)
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await run(item) }
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(Palette.green)
                    }
                    Button(role: .destructive) {
                        items.removeAll { $0.id == item.id }
                        save()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .padding(10)
                .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
            }
            if !history.isEmpty { ModuleResponse(value: history, failed: error) }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "aio.automation.actions"),
              let decoded = try? JSONDecoder().decode([SavedAction].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "aio.automation.actions")
        }
    }

    @MainActor
    private func run(_ item: SavedAction) async {
        busy = true
        defer { busy = false }
        do {
            switch item.kind {
            case "Скопировать текст":
                UIPasteboard.general.string = item.content
                history = "Скопировано: \(item.title)"
            case "Открыть сайт":
                let url = try ModuleURL.secure(item.content)
                guard await UIApplication.shared.open(url) else {
                    throw ModuleOperationError("iOS не смогла открыть URL.")
                }
                history = "Открыто: \(url.host ?? "")"
            case "Проверить HTTPS":
                let url = try ModuleURL.secure(item.content)
                let (_, response) = try await ModuleHTTP.request(url, method: "HEAD")
                history = "\(item.title): HTTP \(response.statusCode)"
            default:
                throw ModuleOperationError("Неизвестный тип действия.")
            }
            error = false
        } catch {
            history = error.localizedDescription
            self.error = true
        }
    }
}
