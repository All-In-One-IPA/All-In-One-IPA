import SwiftUI

enum ModuleCategory: String, CaseIterable, Identifiable {
    case network, remote, media, utilities, system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .network: "Сеть"
        case .remote: "Удалённый доступ"
        case .media: "Медиа и файлы"
        case .utilities: "Инструменты"
        case .system: "Система"
        }
    }

    var tint: Color {
        switch self {
        case .network: Palette.cyan
        case .remote: Palette.green
        case .media: Palette.lavender
        case .utilities: Palette.amber
        case .system: Palette.coral
        }
    }
}

enum ModuleStatus: String {
    case soon, planned, research, beta

    var title: String {
        switch self {
        case .soon: "Скоро"
        case .planned: "В планах"
        case .research: "Изучаем"
        case .beta: "Бета"
        }
    }

    var tint: Color {
        switch self {
        case .soon: Palette.cyan
        case .planned: Palette.secondary
        case .research: Palette.amber
        case .beta: Palette.green
        }
    }
}

struct ModuleInfo: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let category: ModuleCategory
    let status: ModuleStatus
    let description: String
    let plannedFeatures: [String]
}

enum ModuleCatalog {
    static let all: [ModuleInfo] = [
        .init(id: "tgws", title: "tg-ws-proxy", subtitle: "Локальный прокси Telegram",
              symbol: "network", category: .network, status: .soon,
              description: "Планируется перенос логики Flowseal/tg-ws-proxy в нативный модуль iOS. Это локальный MTProto-прокси, а не relay для Telemt.",
              plannedFeatures: ["Локальная точка подключения Telegram", "Конфигурация и диагностика соединений", "Проверка поведения при фоновой работе"]),
        .init(id: "ssh", title: "SSH / SFTP", subtitle: "Терминал и удалённые файлы",
              symbol: "terminal.fill", category: .remote, status: .soon,
              description: "Рабочее пространство для подключений к Linux-серверам и обмена файлами.",
              plannedFeatures: ["SSH-терминал и ключи", "SFTP-браузер", "Сохранённые подключения и tmux"]),
        .init(id: "dns", title: "DNS Studio", subtitle: "Профили DoH и DoT",
              symbol: "globe.europe.africa.fill", category: .network, status: .soon,
              description: "Редактор DNS-профилей для iOS с экспортом конфигурации и предварительной проверкой.",
              plannedFeatures: ["Генерация mobileconfig", "Проверка DNS-адресов", "Экспорт через системное меню"]),
        .init(id: "player", title: "Плеер", subtitle: "Музыка и видео без лишнего",
              symbol: "play.rectangle.fill", category: .media, status: .planned,
              description: "Локальная медиатека с удобным просмотром и воспроизведением собственных файлов.",
              plannedFeatures: ["Локальные аудио и видео", "Плейлисты", "Интеграция с файлами"]),
        .init(id: "torrent", title: "Торренты", subtitle: "Загрузка и управление",
              symbol: "arrow.down.circle.fill", category: .media, status: .research,
              description: "Будущий торрент-клиент и управление удалёнными загрузками. Долгая фоновая P2P-работа на iOS не гарантируется.",
              plannedFeatures: ["Magnet и torrent-файлы", "Управление файлами и прогрессом", "Удалённые загрузчики"]),
        .init(id: "mail", title: "Почта", subtitle: "Несколько ящиков в одном месте",
              symbol: "envelope.fill", category: .utilities, status: .planned,
              description: "Персональный почтовый клиент с поддержкой стандартных почтовых протоколов.",
              plannedFeatures: ["IMAP и SMTP", "Несколько аккаунтов", "Поиск и вложения"]),
        .init(id: "keyboard", title: "Клавиатура", subtitle: "Собственная раскладка",
              symbol: "keyboard.fill", category: .system, status: .beta,
              description: "Системное расширение iOS с русской и английской раскладками, цифрами, символами и локальным оформлением. Совместимость с xtool проверяется.",
              plannedFeatures: ["Русская и английская раскладки", "Регистр и Caps Lock", "Цифры, символы, оформление без Full Access"]),
        .init(id: "beszel", title: "Beszel", subtitle: "Мониторинг устройств",
              symbol: "chart.xyaxis.line", category: .remote, status: .planned,
              description: "Клиент для просмотра мониторинга Beszel. Полноценный агент самого iPhone ограничен системой.",
              plannedFeatures: ["Карточки узлов", "Метрики и графики", "Состояние сервисов"]),
        .init(id: "network", title: "Network Lab", subtitle: "Проверки и диагностика",
              symbol: "waveform.path.ecg", category: .network, status: .planned,
              description: "Набор сетевых проверок, не требующих системного перехвата пакетов.",
              plannedFeatures: ["Ping и проверки TCP", "HTTP-заголовки", "История тестов"]),
        .init(id: "archives", title: "Архивы", subtitle: "Распаковка и управление",
              symbol: "doc.zipper", category: .media, status: .planned,
              description: "Работа с файлами и популярными форматами архивов.",
              plannedFeatures: ["Импорт из Files", "Распаковка и упаковка", "Передача в другие модули"]),
        .init(id: "servers", title: "Server Tools", subtitle: "Удалённые службы",
              symbol: "server.rack", category: .remote, status: .planned,
              description: "Удобное управление собственными службами и API.",
              plannedFeatures: ["Docker и HTTP API", "Системные действия", "Безопасное хранение учётных данных"]),
        .init(id: "automation", title: "Автоматизация", subtitle: "Быстрые действия",
              symbol: "bolt.fill", category: .utilities, status: .research,
              description: "Интеграция с Shortcuts и будущие действия внутри приложения.",
              plannedFeatures: ["App Intents", "Действия из Shortcuts", "Сценарии и события"])
    ]

    static func find(_ id: String) -> ModuleInfo {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
