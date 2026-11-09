import Foundation

/// Мониторинг Beszel. Only local configuration until the underlying service is implemented.
enum BeszelModule {
    static let blueprint = ModuleBlueprint(
        id: "beszel",
        headline: "Мониторинг Beszel",
        description: "Подготовка подключения к панели мониторинга своих устройств.",
        groups: [
        ModuleGroup(title: "Панель", inputs: [
            ModuleInput("url", "Адрес панели", "https://monitor.example.com", .url, initialValue: ""),
            ModuleInput("label", "Название подключения", "Домашний сервер", .text, initialValue: "")
        ]),
        ModuleGroup(title: "Обзор", inputs: [
            ModuleInput("refresh", "Интервал обновления", "30 с", .options(["15 с", "30 с", "60 с"]), initialValue: "15 с")
        ])
        ],
        milestones: [
            "HTTP-клиент Beszel и авторизация",
            "Графики CPU, памяти, диска и сети",
            "Состояния узлов и история событий"
        ],
        privacyNotice: "Сейчас не производится опрос панели. Учётные данные позднее будут храниться в Keychain."
    )
}
