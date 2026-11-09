import Foundation

/// Автоматизация. Only local configuration until the underlying service is implemented.
enum AutomationModule {
    static let blueprint = ModuleBlueprint(
        id: "automation",
        headline: "Автоматизация",
        description: "Набросок будущих App Intents и быстрых действий в Shortcuts.",
        groups: [
        ModuleGroup(title: "Шаблон действия", inputs: [
            ModuleInput("name", "Название действия", "Моё действие", .text, initialValue: ""),
            ModuleInput("trigger", "Тип запуска", "Вручную", .options(["Вручную", "Через Shortcuts"]), initialValue: "Вручную"),
            ModuleInput("notes", "Описание", "Что должно происходить", .text, initialValue: "")
        ])
        ],
        milestones: [
            "App Intents и обнаружение действий в Shortcuts",
            "Локальные сценарии без постоянного фонового процесса",
            "История запусков, ошибки и повтор выполнения"
        ],
        privacyNotice: "iOS не разрешает произвольно держать фоновые задачи навсегда; действия пока не выполняются."
    )
}
