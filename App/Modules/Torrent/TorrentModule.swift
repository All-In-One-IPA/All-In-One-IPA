import Foundation

/// Local BitTorrent implementation; the qBittorrent remote API is not used.
enum TorrentModule {
    static let blueprint = ModuleBlueprint(
        id: "torrent",
        headline: "Торренты на iPhone",
        description: "Самостоятельный клиент BitTorrent на базе встроенной Rust-библиотеки librqbit. Все файлы хранятся на этом iPhone.",
        groups: [
            ModuleGroup(title: "Локальное хранилище", inputs: [
                ModuleInput("downloadFolder", "Папка", "Torrents", .text, initialValue: "Torrents")
            ])
        ],
        milestones: [
            "Проверить реальные magnet и .torrent загрузки на iPhone",
            "Скорость, число пиров, приоритет файлов и возобновление",
            "Файловый браузер и интеграция с медиаплеером",
            "Исследовать ограничения фоновой работы iOS"
        ],
        privacyNotice: "Торренты скачиваются на iPhone через прямые P2P-соединения. Движок не отправляет данные на qBittorrent или другой промежуточный сервер."
    )
}
