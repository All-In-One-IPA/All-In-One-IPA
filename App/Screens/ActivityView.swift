import SwiftUI

struct ActivityView: View {
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 23) {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "ЖУРНАЛ")
                        Text("События")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text("Задачи, подключения и история действий.")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.secondary)
                    }

                    HStack(spacing: 14) {
                        Image(systemName: "circle.dotted.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.cyan)
                            .frame(width: 45, height: 45)
                            .background(Palette.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Режим предпросмотра")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                            Text("Службы пока не подключены")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(17)
                    .surfaceCard(radius: 21)

                    SectionHeading(title: "История")
                    QuietEmptyState(
                        symbol: "clock.arrow.circlepath",
                        title: "Здесь пока тихо",
                        message: "Когда появятся рабочие модули, в этом разделе будут отображаться задачи, подключения и их результаты."
                    )

                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(Palette.green)
                        Text("Журнал будет храниться локально. Никаких выдуманных соединений или демонстрационных результатов.")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                }
                .padding(.horizontal, 20)
                .padding(.top, 17)
                .padding(.bottom, 35)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
