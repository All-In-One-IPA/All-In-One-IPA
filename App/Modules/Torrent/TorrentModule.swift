import Foundation

/// Загрузки и торренты. Only local configuration until the underlying service is implemented.
enum TorrentModule {
    static let blueprint = ModuleBlueprint(
        id: "torrent",
        headline: "Загрузки и торренты",
        description: "Параметры для будущего локального и удалённого торрент-движка.",
        groups: [
        ModuleGroup(title: "Загрузчик", inputs: [
            ModuleInput("engine", "Режим", "Удалённый", .options(["Удалённый", "Локальный (эксперимент)"]), initialValue: "Удалённый"),
            ModuleInput("url", "Адрес удалённого клиента", "https://example.com/qbt", .url, initialValue: ""),
            ModuleInput("saveFolder", "Папка загрузок", "Downloads", .text, initialValue: "Downloads")
        ])
        ],
        milestones: [
            "Поддержка magnet и torrent-файлов",
            "Интеграция с удалённым qBittorrent API",
            "Исследование локального движка и ограничений фона iOS"
        ],
        privacyNotice: "Фоновые P2P-сессии в iOS не гарантируются. Указанный адрес сейчас не используется для запросов."
    )
}
