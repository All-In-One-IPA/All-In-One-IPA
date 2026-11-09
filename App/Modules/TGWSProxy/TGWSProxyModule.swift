import Foundation

/// Локальный прокси Telegram. Only local configuration until the underlying service is implemented.
enum TGWSProxyModule {
    static let blueprint = ModuleBlueprint(
        id: "tgws",
        headline: "Локальный прокси Telegram",
        description: "Рабочий локальный SOCKS5-релей (TCP) для тестов в активном приложении. MTProto-over-WebSocket протокол Flowseal пока в разработке.",
        groups: [
        ModuleGroup(title: "Локальная точка", inputs: [
            ModuleInput("listenPort", "Порт SOCKS5 на устройстве", "1080", .port, initialValue: "1080"),
            ModuleInput("protocol", "Рабочий режим", "SOCKS5 (прямой)", .options(["SOCKS5 (прямой)"]), initialValue: "SOCKS5 (прямой)")
        ]),
        ModuleGroup(title: "Подключение", inputs: [
            ModuleInput("upstream", "Адрес WebSocket", "wss://example.com/ws", .url, initialValue: ""),
            ModuleInput("profile", "Имя профиля", "Мой профиль", .text, initialValue: "")
        ])
        ],
        milestones: [
            "Перенести локальный транспорт Flowseal/tg-ws-proxy",
            "Добавить запуск и остановку с журналом",
            "Проверить ограничения iOS на фоновые соединения"
        ],
        privacyNotice: "Не указывай токены и пароли в адресах. Параметры пока сохраняются без сетевого соединения."
    )
}
