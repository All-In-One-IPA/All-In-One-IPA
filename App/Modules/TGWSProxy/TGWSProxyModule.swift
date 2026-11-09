import Foundation

/// Локальный прокси Telegram. Only local configuration until the underlying service is implemented.
enum TGWSProxyModule {
    static let blueprint = ModuleBlueprint(
        id: "tgws",
        headline: "Локальный прокси Telegram",
        description: "Основа для будущего переноса Flowseal/tg-ws-proxy. Здесь пока сохраняются параметры, а сам прокси не запускается.",
        groups: [
        ModuleGroup(title: "Локальная точка", inputs: [
            ModuleInput("listenPort", "Порт на устройстве", "1080", .port, initialValue: "1080"),
            ModuleInput("protocol", "Протокол Telegram", "MTProto / SOCKS5", .options(["MTProto", "SOCKS5"]), initialValue: "MTProto")
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
