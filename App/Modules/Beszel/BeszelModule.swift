import Foundation

enum BeszelModule {
    static let blueprint = ModuleBlueprint(
        id: "beszel",
        headline: "Beszel Agent на iPhone",
        description: "Телефон выступает агентом: подключается к существующему Beszel Hub, обменивается токеном и подписанным вызовом, затем предоставляет доступные метрики.",
        groups: [
            ModuleGroup(title: "Beszel Hub", inputs: [
                ModuleInput("url", "URL хаба (HTTPS)", "https://beszel.example.com", .url),
                ModuleInput("label", "Имя iPhone в панели", "iPhone", .text, initialValue: "iPhone")
            ])
        ],
        milestones: [
            "Проверить WebSocket-регистрацию с настоящим Beszel Hub",
            "Добавить дополнительные разрешённые iOS показатели",
            "Улучшить переподключение и отображение ответов хаба",
            "Фоновая отправка не планируется без подходящих прав iOS"
        ],
        privacyNotice: "Подключение происходит только после твоего действия и прекращается при выходе из рабочего пространства или сворачивании приложения. Токен хранится в Keychain, а открытый ключ хаба проверяет его подпись."
    )
}
