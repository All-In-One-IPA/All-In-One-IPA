import Foundation

/// Почта. Only local configuration until the underlying service is implemented.
enum MailModule {
    static let blueprint = ModuleBlueprint(
        id: "mail",
        headline: "Почта",
        description: "Конфигурация будущего IMAP/SMTP-клиента без ввода пароля в открытом виде.",
        groups: [
        ModuleGroup(title: "Почтовый ящик", inputs: [
            ModuleInput("address", "Email", "user@example.com", .text, initialValue: ""),
            ModuleInput("incoming", "IMAP-сервер", "imap.example.com", .hostname, initialValue: ""),
            ModuleInput("incomingPort", "Порт IMAP", "993", .port, initialValue: "993")
        ]),
        ModuleGroup(title: "Отправка", inputs: [
            ModuleInput("outgoing", "SMTP-сервер", "smtp.example.com", .hostname, initialValue: ""),
            ModuleInput("outgoingPort", "Порт SMTP", "465", .port, initialValue: "465")
        ])
        ],
        milestones: [
            "Безопасная авторизация OAuth2 / App Password через Keychain",
            "Синхронизация IMAP-папок и писем",
            "Отправка через SMTP и вложения"
        ],
        privacyNotice: "Пароли не запрашиваются и не сохраняются. Почтовые соединения ещё не выполняются."
    )
}
