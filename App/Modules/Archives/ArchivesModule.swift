import Foundation

/// Файлы и архивы. Only local configuration until the underlying service is implemented.
enum ArchivesModule {
    static let blueprint = ModuleBlueprint(
        id: "archives",
        headline: "Файлы и архивы",
        description: "Параметры будущего менеджера архивов в собственной песочнице приложения.",
        groups: [
        ModuleGroup(title: "Архивы", inputs: [
            ModuleInput("format", "Формат по умолчанию", "ZIP", .options(["ZIP", "TAR", "7z (позднее)"]), initialValue: "ZIP"),
            ModuleInput("folder", "Рабочая папка", "Archives", .text, initialValue: "Archives")
        ])
        ],
        milestones: [
            "Импорт из Files и распаковка ZIP/TAR",
            "Создание архивов, контрольные суммы",
            "Предпросмотр, экспорт и управление хранилищем"
        ],
        privacyNotice: "Ни один файл пока не меняется. Доступ к чужим файлам будет только через системный выбор."
    )
}
