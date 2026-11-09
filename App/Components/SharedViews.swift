import SwiftUI

struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.6)
            .foregroundStyle(Palette.secondary)
    }
}

struct StatusPill: View {
    let status: ModuleStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}

struct ModuleGlyph: View {
    let module: ModuleInfo
    var size: CGFloat = 48

    var body: some View {
        Image(systemName: module.symbol)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(module.category.tint)
            .frame(width: size, height: size)
            .background(module.category.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct SectionHeading: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.ink)
            Spacer()
            if let trailing, let action {
                Button(trailing, action: action)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.cyan)
            }
        }
    }
}

struct ModuleListRow: View {
    let module: ModuleInfo

    var body: some View {
        NavigationLink {
            if module.id == "keyboard" {
                KeyboardSettingsView()
            } else {
                ModuleDetailView(module: module)
            }
        } label: {
            HStack(spacing: 14) {
                ModuleGlyph(module: module, size: 52)
                VStack(alignment: .leading, spacing: 5) {
                    Text(module.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(module.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 10) {
                    StatusPill(status: module.status)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.secondary)
                }
            }
            .padding(15)
            .surfaceCard(radius: 20)
        }
        .buttonStyle(.plain)
    }
}

struct QuietEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Palette.cyan)
                .frame(width: 84, height: 84)
                .background(Palette.cyan.opacity(0.10), in: RoundedRectangle(cornerRadius: 25))
            Text(title)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.ink)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Palette.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .surfaceCard(radius: 26)
    }
}
