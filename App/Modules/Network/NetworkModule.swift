import Foundation

/// Сетевая диагностика. Only local configuration until the underlying service is implemented.
enum NetworkModule {
    static let blueprint = ModuleBlueprint(
        id: "network",
        headline: "Сетевая диагностика",
        description: "Первая полезная проверка уже доступна: HTTP HEAD запрос для HTTPS-адреса. Результат отображается ниже.",
        groups: [
        ModuleGroup(title: "Проверка", inputs: [
            ModuleInput("target", "Целевой HTTPS URL", "https://example.com", .url, initialValue: "https://example.com")
        ]),
        ModuleGroup(title: "Предпочтения", inputs: [
            ModuleInput("timeout", "Тайм-аут в секундах", "8", .port, initialValue: "8")
        ])
        ],
        milestones: [
            "TCP-подключение с измерением задержки",
            "DNS lookup и расширенная статистика",
            "История проверок и экспорт результатов"
        ],
        privacyNotice: "Тест отправляет сетевой запрос только после явного нажатия кнопки. Он не обходит ограничения iOS."
    )
}
