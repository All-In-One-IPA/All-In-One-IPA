import SwiftUI

/// Each module is an independent workspace tab; the bottom navigation keeps
/// only five primary destinations rather than creating 12 cramped iOS tabs.
struct ModulesView: View {
    @Binding var selectedModule: String

    private var activeModule: ModuleInfo {
        ModuleCatalog.find(selectedModule)
    }

    var body: some View {
        VStack(spacing: 0) {
            moduleTabs
            Divider().overlay(Palette.hairline)
            Group {
                if selectedModule == "keyboard" {
                    KeyboardSettingsView()
                } else {
                    ModuleDetailView(module: activeModule)
                }
            }
            .id(selectedModule)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var moduleTabs: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(text: "РАБОЧИЕ ПРОСТРАНСТВА")
                    Text("Модули")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                }
                Spacer()
                Text("\(ModuleCatalog.all.count)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.secondary)
            }
            .padding(.horizontal, 20)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ModuleCatalog.all) { module in
                            moduleTab(module)
                                .id(module.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)
                }
                .onAppear {
                    proxy.scrollTo(selectedModule, anchor: .center)
                }
                .onChange(of: selectedModule) { _, newID in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 9)
        .background(Palette.surface)
    }

    private func moduleTab(_ module: ModuleInfo) -> some View {
        let active = selectedModule == module.id
        return Button {
            selectedModule = module.id
        } label: {
            HStack(spacing: 7) {
                Image(systemName: module.symbol)
                    .font(.system(size: 13))
                Text(module.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(active ? Palette.background : Palette.secondary)
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(active ? Palette.cyan : Palette.background,
                        in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(active ? Color.clear : Palette.hairline, lineWidth: 0.7)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }
}
