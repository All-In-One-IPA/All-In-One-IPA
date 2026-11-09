import SwiftUI

struct ModuleDetailView: View {
    let module: ModuleInfo

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ModuleGlyph(module: module, size: 70)
                            Spacer()
                            StatusPill(status: module.status)
                        }
                        VStack(alignment: .leading, spacing: 7) {
                            Text(module.title)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Text(module.subtitle)
                                .font(.system(size: 15))
                                .foregroundStyle(Palette.secondary)
                        }
                        Text(module.description)
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.ink)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .surfaceCard(radius: 27)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "Что планируется")
                        ForEach(Array(module.plannedFeatures.enumerated()), id: \.offset) { index, feature in
                            HStack(alignment: .top, spacing: 14) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(module.category.tint)
                                    .frame(width: 26)
                                Text(feature)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.ink)
                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .surfaceCard(radius: 17)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Palette.cyan)
                        Text("Сейчас это интерфейс будущего модуля. Он не запускает службы и не устанавливает соединения.")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 17))
                }
                .padding(20)
            }
        }
        .navigationTitle("О модуле")
        .navigationBarTitleDisplayMode(.inline)
    }
}
