import Foundation

enum ModuleInputKind {
    case text
    case hostname
    case url
    case port
    case options([String])
}

struct ModuleInput: Identifiable {
    let id: String
    let title: String
    let placeholder: String
    let kind: ModuleInputKind
    let initialValue: String

    init(_ id: String, _ title: String, _ placeholder: String,
         _ kind: ModuleInputKind = .text, initialValue: String = "") {
        self.id = id
        self.title = title
        self.placeholder = placeholder
        self.kind = kind
        self.initialValue = initialValue
    }
}

struct ModuleGroup: Identifiable {
    let title: String
    let inputs: [ModuleInput]
    var id: String { title }
}

struct ModuleBlueprint {
    let id: String
    let headline: String
    let description: String
    let groups: [ModuleGroup]
    let milestones: [String]
    let privacyNotice: String

    var allInputs: [ModuleInput] { groups.flatMap(\.inputs) }
}

/// Every non-keyboard module has a separate definition file.
/// Individual modules can replace their blueprint with a real implementation later.
enum ModuleRegistry {
    static let blueprints: [String: ModuleBlueprint] = {
        let all = [
            TGWSProxyModule.blueprint, SSHModule.blueprint, DNSModule.blueprint,
            MediaModule.blueprint, TorrentModule.blueprint, MailModule.blueprint,
            BeszelModule.blueprint, NetworkModule.blueprint, ArchivesModule.blueprint,
            ServerToolsModule.blueprint, AutomationModule.blueprint
        ]
        return Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static func blueprint(for id: String) -> ModuleBlueprint? { blueprints[id] }
}
