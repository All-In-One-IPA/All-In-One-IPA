import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 7) {
                        Eyebrow(text: "ПАРАМЕТРЫ")
                        Text("Настройки")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text("Сделай пространство своим.")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(title: "Оформление")
                        VStack(alignment: .leading, spacing: 11) {
                            Label("Тема приложения", systemImage: "paintpalette")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                            Picker("Тема", selection: $appearance) {
                                ForEach(Appearance.allCases) { item in
                                    Text(item.title).tag(item.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            Text("Системная тема автоматически следует настройкам iOS.")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.secondary)
                        }
                        .padding(17)
                        .surfaceCard(radius: 21)
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeading(title: "Клавиатура")
                        NavigationLink {
                            KeyboardSettingsView()
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "keyboard.fill")
                                    .foregroundStyle(Palette.coral)
                                    .frame(width: 34, height: 34)
                                    .background(Palette.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("All-In-One Keyboard")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Palette.ink)
                                    Text("Подключить и протестировать")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Palette.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Palette.secondary)
                            }
                            .padding(16)
                            .surfaceCard(radius: 18)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeading(title: "О приложении")
                        infoRow(symbol: "square.stack.3d.up", title: "Версия", value: version)
                        infoRow(symbol: "hammer", title: "Этап", value: "Модули")
                        infoRow(symbol: "iphone", title: "Платформа", value: "iOS 17+")
                        Link(destination: URL(string: "https://github.com/All-In-One-IPA/All-In-One-IPA")!) {
                            HStack(spacing: 13) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Palette.cyan)
                                    .frame(width: 31)
                                Text("Исходный код")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.secondary)
                            }
                            .padding(16)
                            .surfaceCard(radius: 16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "ПРИВАТНОСТЬ")
                        Text("Никаких внешних аккаунтов, аналитики или фоновых сервисов в этой версии. Сохранённые адреса устройств остаются на iPhone.")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.secondary)
                            .lineSpacing(4)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceCard(radius: 21)

                    Text("ALL-IN-ONE  /  BUILT FOR YOUR OWN WORKFLOW")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(Palette.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 17)
                .padding(.bottom, 35)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private func infoRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .foregroundStyle(Palette.cyan)
                .frame(width: 31)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(Palette.secondary)
        }
        .padding(16)
        .surfaceCard(radius: 16)
    }
}
