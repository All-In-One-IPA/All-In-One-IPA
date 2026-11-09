import Foundation

/// Server Tools. Only local configuration until the underlying service is implemented.
enum ServerToolsModule {
    static let blueprint = ModuleBlueprint(
        id: "servers",
        headline: "Server Tools",
        description: "Основа для работы с Docker, службами и HTTP API собственных серверов.",
        groups: [
        ModuleGroup(title: "API", inputs: [
            ModuleInput("endpoint", "Базовый URL", "https://api.example.com", .url, initialValue: ""),
            ModuleInput("name", "Название сервиса", "Домашний API", .text, initialValue: ""),
            ModuleInput("method", "Метод запросов", "GET", .options(["GET", "POST", "PUT", "DELETE"]), initialValue: "GET")
        ])
        ],
        milestones: [
            "Типизированные API-клиенты и безопасная авторизация",
            "Обзор контейнеров и журналов Docker",
            "Подтверждаемые действия запуска и остановки"
        ],
        privacyNotice: "Кнопки управления сервером появятся только после реализации авторизации и защитных подтверждений."
    )
}
