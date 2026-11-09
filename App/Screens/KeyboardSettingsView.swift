import SwiftUI
import UIKit

struct KeyboardSettingsView: View {
    @State private var sample = "Привет! Это моя клавиатура."
    @FocusState private var demoFocused: Bool

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    setup
                    testField
                    capabilities
                    privacy
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Клавиатура")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Palette.coral)
                    .frame(width: 72, height: 72)
                    .background(Palette.coral.opacity(0.13),
                                in: RoundedRectangle(cornerRadius: 23))
                Spacer()
                StatusPill(status: .beta)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Твой способ печатать.")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)

                Text("Русский и английский, собственная палитра и всё необходимое для повседневного ввода.")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(21)
        .surfaceCard(radius: 26)
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(title: "Подключение")

            instruction(1, "Открой «Настройки» iPhone",
                        "Основные → Клавиатура → Клавиатуры.")
            instruction(2, "Добавь новую клавиатуру",
                        "Выбери All-In-One Keyboard в списке сторонних.")
            instruction(3, "Переключись на неё",
                        "Открой любое текстовое поле и удерживай кнопку глобуса.")

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 9) {
                    Text("Открыть настройки All-In-One")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.cyan)
                .padding(15)
                .surfaceCard(radius: 16)
            }
            .buttonStyle(.plain)

            Text("Кнопка открывает настройки приложения, а не раздел клавиатур. Если нужного пункта нет, пройди путь выше вручную.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func instruction(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Text(String(number))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.background)
                .frame(width: 30, height: 30)
                .background(Palette.cyan, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .surfaceCard(radius: 19)
    }

    private var testField: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "Проверка")
            VStack(alignment: .leading, spacing: 9) {
                Eyebrow(text: "ПОЛЕ ДЛЯ ТЕСТА")

                TextEditor(text: $sample)
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                    .focused($demoFocused)
                    .accessibilityLabel("Тестовое поле ввода клавиатуры")

                HStack {
                    Text("Нажми сюда и выбери All-In-One в меню клавиатур.")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.secondary)
                    Spacer(minLength: 0)
                    if !sample.isEmpty {
                        Button("Очистить") { sample = "" }
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }
            .padding(16)
            .surfaceCard(radius: 20)
        }
    }

    private var capabilities: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Уже работает")

            VStack(spacing: 0) {
                feature("character.book.closed", "RU / EN", "Раскладки с отдельным переключателем")
                Divider().overlay(Palette.hairline).padding(.leading, 55)
                feature("shift", "Регистр и Caps Lock", "Двойное нажатие Shift блокирует регистр")
                Divider().overlay(Palette.hairline).padding(.leading, 55)
                feature("number", "Цифры и символы", "Базовые знаки и отдельные страницы")
                Divider().overlay(Palette.hairline).padding(.leading, 55)
                feature("paintpalette", "Светлая и тёмная тема", "Переключение прямо над клавишами")
            }
            .padding(.horizontal, 14)
            .surfaceCard(radius: 20)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(Palette.coral)
                .frame(width: 40, height: 45)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private var privacy: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Palette.green)
            VStack(alignment: .leading, spacing: 7) {
                Text("Без полного доступа")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text("Клавиатура работает локально. Разрешение Full Access не требуется, текст никуда не отправляется. В полях паролей и некоторых приложениях iOS использует системную клавиатуру.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard(radius: 21)
    }
}
