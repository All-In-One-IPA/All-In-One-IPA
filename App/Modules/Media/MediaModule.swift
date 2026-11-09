import Foundation

/// Медиатека. Only local configuration until the underlying service is implemented.
enum MediaModule {
    static let blueprint = ModuleBlueprint(
        id: "player",
        headline: "Медиатека",
        description: "Основа для воспроизведения локальных аудио и видео и работы с файлами iOS.",
        groups: [
        ModuleGroup(title: "Медиатека", inputs: [
            ModuleInput("libraryName", "Название библиотеки", "Личная коллекция", .text, initialValue: "Личная коллекция"),
            ModuleInput("playback", "Режим воспроизведения", "По порядку", .options(["По порядку", "Повтор", "Случайно"]), initialValue: "По порядку")
        ])
        ],
        milestones: [
            "Импорт и безопасное хранение выбранных файлов",
            "AVPlayer, очередь, скорость и субтитры",
            "Плейлисты, обложки и метаданные"
        ],
        privacyNotice: "Реального импорта и воспроизведения пока нет. Библиотеки других приложений не читаются автоматически."
    )
}
