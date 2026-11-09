import Foundation

/// SSH и удалённые файлы. Only local configuration until the underlying service is implemented.
enum SSHModule {
    static let blueprint = ModuleBlueprint(
        id: "ssh",
        headline: "SSH и удалённые файлы",
        description: "Адресная книга подключений и будущие SSH/SFTP-сессии. Ключи и пароли не сохраняются в этих полях.",
        groups: [
        ModuleGroup(title: "Подключение", inputs: [
            ModuleInput("host", "Имя узла", "192.168.1.10 или server.example.com", .hostname, initialValue: ""),
            ModuleInput("port", "SSH порт", "22", .port, initialValue: "22"),
            ModuleInput("username", "Пользователь", "root", .text, initialValue: "root")
        ]),
        ModuleGroup(title: "Рабочая сессия", inputs: [
            ModuleInput("startPath", "Начальная папка SFTP", "/home", .text, initialValue: "/home"),
            ModuleInput("terminal", "Профиль терминала", "Стандартный", .options(["Стандартный", "Компактный"]), initialValue: "Стандартный")
        ])
        ],
        milestones: [
            "Добавить SSH-транспорт и хранилище ключей в Keychain",
            "Интерактивный терминал и tmux",
            "Просмотр, выгрузка и скачивание файлов по SFTP"
        ],
        privacyNotice: "Секреты не сохраняются в UserDefaults. После реализации для них предусмотрим Keychain."
    )
}
