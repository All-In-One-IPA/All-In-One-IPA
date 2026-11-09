import SwiftUI

struct ModuleActionCard<Content: View>: View {
    let title: String
    let symbol: String
    let content: () -> Content

    init(title: String, symbol: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(Palette.cyan)
                    .frame(width: 23)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
            content()
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard(radius: 21)
    }
}

struct ModuleRunButton: View {
    let title: String
    var symbol = "play.fill"
    var busy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if busy { ProgressView().tint(Palette.background) }
                else { Image(systemName: symbol) }
                Text(busy ? "Выполняется..." : title)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Palette.cyan, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }
}

struct ModuleResponse: View {
    let value: String
    var failed = false

    var body: some View {
        Text(value)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(failed ? Palette.coral : Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(12)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ModuleField: View {
    let title: String
    var placeholder = ""
    @Binding var value: String
    var secure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
            Group {
                if secure {
                    SecureField(placeholder, text: $value)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: $value)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 14))
            .foregroundStyle(Palette.ink)
            .padding(12)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ModuleActionPanel: View {
    let moduleID: String
    @Binding var values: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "Рабочие инструменты")
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch moduleID {
        case "tgws": TelegramProxyActionView(values: $values)
        case "ssh": SSHActionView(values: $values)
        case "dns": DNSActionView(values: $values)
        case "player": MediaActionView(values: $values)
        case "torrent": TorrentActionView(values: $values)
        case "mail": MailActionView(values: $values)
        case "beszel": BeszelActionView(values: $values)
        case "network": NetworkActionView(values: $values)
        case "archives": ArchiveActionView(values: $values)
        case "servers": ServerActionView(values: $values)
        case "automation": AutomationActionView(values: $values)
        default: EmptyView()
        }
    }
}
