import SwiftUI

@main
struct AllInOneApp: App {
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .tint(Palette.cyan)
        }
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, dark, light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Система"
        case .dark: "Тёмная"
        case .light: "Светлая"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

enum AppTab: Hashable {
    case home, modules, activity, devices, settings
}

struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = .home
    @State private var selectedModule = "torrent"

    private func openModule(_ id: String) {
        selectedModule = id
        selection = .modules
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView(openModules: { selection = .modules }, openModule: openModule)
            }
            .tabItem { Label("Главная", systemImage: "square.grid.2x2.fill") }
            .tag(AppTab.home)

            NavigationStack {
                ModulesView(selectedModule: $selectedModule)
            }
            .tabItem { Label("Модули", systemImage: "square.stack.3d.up.fill") }
            .tag(AppTab.modules)

            NavigationStack {
                ActivityView()
            }
            .tabItem { Label("События", systemImage: "waveform.path") }
            .tag(AppTab.activity)

            NavigationStack {
                DevicesView()
            }
            .tabItem { Label("Устройства", systemImage: "externaldrive.connected.to.line.below") }
            .tag(AppTab.devices)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Настройки", systemImage: "slider.horizontal.3") }
            .tag(AppTab.settings)
        }
        .toolbarBackground(Palette.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                BeszelLiveAgent.shared.stop(reason: "iOS приостановила приложение.")
                Task { await LocalTorrentEngine.shared.stop() }
            }
        }
    }
}
