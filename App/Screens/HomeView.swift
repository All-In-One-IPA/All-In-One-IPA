import SwiftUI

struct HomeView: View {
    let openModules: () -> Void
    private let highlights = ["keyboard", "ssh", "dns", "player"]

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    hero
                    featured
                    quickTools
                    upcoming
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 17)
                .padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "ALL-IN-ONE · 0.2")
                Text("Главная")
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .tracking(-0.9)
                    .foregroundStyle(Palette.ink)
            }
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Palette.cyan)
                .frame(width: 44, height: 44)
                .surfaceCard(radius: 15)
                .accessibilityHidden(true)
        }
    }

    private var hero: some View {
        Button(action: openModules) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .fill(LinearGradient(colors: [
                        Color(red: 0.12, green: 0.28, blue: 0.33),
                        Color(red: 0.09, green: 0.16, blue: 0.24),
                        Color(red: 0.11, green: 0.14, blue: 0.23)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .strokeBorder(Palette.cyan.opacity(0.25), lineWidth: 1)
                    .frame(width: 210, height: 210)
                    .offset(x: 205, y: -80)
                Circle()
                    .strokeBorder(Palette.cyan.opacity(0.12), lineWidth: 1)
                    .frame(width: 290, height: 290)
                    .offset(x: 164, y: -118)

                VStack(alignment: .leading, spacing: 15) {
                    Label("РАЗВИВАЕМСЯ", systemImage: "circle.dotted")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Palette.cyan)
                    Text("Один дом.\nДля всего.")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Сеть, файлы, серверы и медиа.\nВсё, что нужно, — под рукой.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.74))
                        .lineSpacing(3)

                    HStack(spacing: 8) {
                        Text("Смотреть модули")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.10, green: 0.19, blue: 0.22))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .background(Palette.cyan, in: Capsule())
                    .padding(.top, 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(25)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 29, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(title: "В центре внимания")
            NavigationLink {
                ModuleDetailView(module: ModuleCatalog.find("tgws"))
            } label: {
                HStack(alignment: .top, spacing: 15) {
                    ModuleGlyph(module: ModuleCatalog.find("tgws"), size: 55)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text("tg-ws-proxy")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Spacer(minLength: 4)
                            StatusPill(status: .soon)
                        }
                        Text("Локальный прокси Telegram")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.secondary)
                        Text("Интеграция Flowseal/tg-ws-proxy. Сначала интерфейс, затем сетевой движок.")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.secondary)
                            .lineSpacing(3)
                            .padding(.top, 8)
                        HStack(spacing: 6) {
                            Text("Подробнее")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.cyan)
                        .padding(.top, 5)
                    }
                }
                .padding(18)
                .surfaceCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var quickTools: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(title: "Ближайшие модули", trailing: "Все", action: openModules)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(highlights, id: \.self) { id in
                        let module = ModuleCatalog.find(id)
                        NavigationLink {
                            if module.id == "keyboard" {
                                KeyboardSettingsView()
                            } else {
                                ModuleDetailView(module: module)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 17) {
                                ModuleGlyph(module: module, size: 44)
                                Spacer(minLength: 2)
                                Text(module.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text(module.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Palette.secondary)
                                    .lineLimit(2)
                                StatusPill(status: module.status)
                            }
                            .frame(width: 132, height: 159, alignment: .leading)
                            .padding(16)
                            .surfaceCard(radius: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.trailing, 20)
            .padding(.trailing, -20)
        }
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Дальше по плану")
            ForEach(["keyboard", "mail", "beszel"], id: \.self) { id in
                let module = ModuleCatalog.find(id)
                NavigationLink {
                    if module.id == "keyboard" {
                        KeyboardSettingsView()
                    } else {
                        ModuleDetailView(module: module)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(module.category.tint).frame(width: 6, height: 6)
                        Text(module.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text(module.status.title)
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Palette.secondary)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 13)
                    .surfaceCard(radius: 15)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        Text("MODULE MVP  /  FOREGROUND SERVICES ONLY")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .tracking(0.6)
            .foregroundStyle(Palette.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}
