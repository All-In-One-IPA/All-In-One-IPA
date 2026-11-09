import SwiftUI

/// Route to each module's own blueprint. Keyboard has its own native extension.
struct ModuleDetailView: View {
    let module: ModuleInfo

    var body: some View {
        if let blueprint = ModuleRegistry.blueprint(for: module.id) {
            ModuleWorkspaceView(module: module, blueprint: blueprint)
        } else {
            ZStack {
                Palette.background.ignoresSafeArea()
                QuietEmptyState(symbol: module.symbol, title: module.title,
                                message: "Этот модуль пока не настроен.")
                    .padding(20)
            }
            .navigationTitle(module.title)
        }
    }
}
