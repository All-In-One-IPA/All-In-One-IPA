import Foundation

/// Редактор DNS-профилей. Only local configuration until the underlying service is implemented.
enum DNSModule {
    static let blueprint = ModuleBlueprint(
        id: "dns",
        headline: "Редактор DNS-профилей",
        description: "Готовим локальные профили DoH и DoT. Применение системного DNS и экспорт mobileconfig добавим отдельно.",
        groups: [
        ModuleGroup(title: "DNS-сервер", inputs: [
            ModuleInput("mode", "Режим", "DoH", .options(["DoH", "DoT"]), initialValue: "DoH"),
            ModuleInput("endpoint", "Адрес резолвера", "https://dns.example.com/dns-query", .url, initialValue: ""),
            ModuleInput("serverName", "Имя сервера DoT", "dns.example.com", .hostname, initialValue: "")
        ]),
        ModuleGroup(title: "Экспорт", inputs: [
            ModuleInput("display", "Название профиля", "All-In-One DNS", .text, initialValue: "All-In-One DNS")
        ])
        ],
        milestones: [
            "Проверка URL и сертификата DNS",
            "Создание подписываемого пользователем mobileconfig",
            "Экспорт через системное меню iOS"
        ],
        privacyNotice: "Профиль ещё не создаётся и не устанавливается: здесь только исходные параметры."
    )
}
