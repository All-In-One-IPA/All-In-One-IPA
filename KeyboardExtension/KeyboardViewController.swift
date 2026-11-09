import UIKit

private enum BoardLanguage: String {
    case ru = "RU", en = "EN"
    var locale: String { self == .ru ? "ru-RU" : "en-US" }
    var space: String { self == .ru ? "пробел" : "space" }
}

private enum BoardPage { case letters, numbers, symbols }
private enum BoardShift { case off, once, locked }
private enum KeyStyle { case ordinary, function, accent, space }

private enum BoardAction {
    case text(String), space, backspace, enter, shift, language, numbers, symbols, letters, globe
}

private struct BoardKey {
    var label: String
    var action: BoardAction
    var weight: CGFloat = 1
    var style: KeyStyle = .ordinary

    static func character(_ value: String) -> BoardKey {
        BoardKey(label: value, action: .text(value))
    }
    static func function(_ title: String, _ action: BoardAction, weight: CGFloat = 1.3) -> BoardKey {
        BoardKey(label: title, action: action, weight: weight, style: .function)
    }
}

private struct BoardPalette {
    let background: UIColor
    let key: UIColor
    let utility: UIColor
    let pressed: UIColor
    let accent: UIColor
    let ink: UIColor
    let secondary: UIColor
    let border: UIColor

    static func forAppearance(dark: Bool) -> Self {
        func color(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                    green: CGFloat((hex >> 8) & 255) / 255,
                    blue: CGFloat(hex & 255) / 255, alpha: 1)
        }
        return dark
            ? Self(background: color(0x151D28), key: color(0x273342),
                   utility: color(0x344356), pressed: color(0x495A70),
                   accent: color(0x65D7D0), ink: color(0xF7FAFC),
                   secondary: color(0xA2B4C8), border: color(0x405064))
            : Self(background: color(0xDEE6EF), key: color(0xFFFFFF),
                   utility: color(0xBFCBD8), pressed: color(0xA8B8C9),
                   accent: color(0x256F78), ink: color(0x1B293B),
                   secondary: color(0x52677C), border: color(0xBAC6D2))
    }
}

private final class BoardButton: UIButton {
    var action: BoardAction = .space
    var standardBackground: UIColor = .white
    var touchingBackground: UIColor = .lightGray

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? touchingBackground : standardBackground }
    }
}

/// Offline RU/EN keyboard. No Full Access, App Group or network entitlements.
final class KeyboardViewController: UIInputViewController {
    private var language: BoardLanguage = .ru
    private var page: BoardPage = .letters
    private var shift: BoardShift = .once
    private var customTheme: Bool?
    private var lastShiftTap: TimeInterval = 0
    private var deleteTimer: Timer?
    private var contentStack: UIStackView?
    private var keyboardHeight: NSLayoutConstraint?

    private var dark: Bool {
        customTheme ?? (traitCollection.userInterfaceStyle == .dark)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let saved = UserDefaults.standard.string(forKey: "keyboard.language"),
           let value = BoardLanguage(rawValue: saved) {
            language = value
        }
        if UserDefaults.standard.object(forKey: "keyboard.dark") != nil {
            customTheme = UserDefaults.standard.bool(forKey: "keyboard.dark")
        }
        let constraint = view.heightAnchor.constraint(equalToConstant: 278)
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
        keyboardHeight = constraint
        adjustShift()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        adjustShift()
        render()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if customTheme == nil &&
            previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            render()
        }
    }

    deinit { deleteTimer?.invalidate() }

    private func render() {
        guard isViewLoaded else { return }
        let palette = BoardPalette.forAppearance(dark: dark)
        view.backgroundColor = palette.background
        contentStack?.removeFromSuperview()

        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 7
        column.distribution = .fill
        column.alignment = .fill
        column.translatesAutoresizingMaskIntoConstraints = false
        column.isLayoutMarginsRelativeArrangement = true
        column.layoutMargins = UIEdgeInsets(top: 7, left: 5, bottom: 8, right: 5)
        column.addArrangedSubview(toolbar(palette))
        for keys in rows() {
            column.addArrangedSubview(row(keys, palette))
        }

        view.addSubview(column)
        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            column.topAnchor.constraint(equalTo: view.topAnchor),
            column.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        contentStack = column
        primaryLanguage = language.locale
    }

    private func toolbar(_ colors: BoardPalette) -> UIView {
        let bar = UIView()
        bar.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let brand = UILabel()
        brand.text = "AIO   /   KEYBOARD"
        brand.font = .systemFont(ofSize: 10, weight: .bold)
        brand.textColor = colors.secondary
        brand.translatesAutoresizingMaskIntoConstraints = false

        let changeLanguageButton = UIButton(type: .system)
        changeLanguageButton.setTitle(language.rawValue, for: .normal)
        changeLanguageButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        changeLanguageButton.tintColor = colors.accent
        changeLanguageButton.addTarget(self, action: #selector(swapLanguage), for: .touchUpInside)
        changeLanguageButton.accessibilityLabel = "Переключить язык"
        changeLanguageButton.translatesAutoresizingMaskIntoConstraints = false

        let theme = UIButton(type: .system)
        theme.setImage(UIImage(systemName: dark ? "sun.max" : "moon"), for: .normal)
        theme.tintColor = colors.secondary
        theme.addTarget(self, action: #selector(swapTheme), for: .touchUpInside)
        theme.accessibilityLabel = "Переключить оформление"
        theme.translatesAutoresizingMaskIntoConstraints = false

        [brand, changeLanguageButton, theme].forEach(bar.addSubview)
        NSLayoutConstraint.activate([
            brand.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            brand.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            changeLanguageButton.trailingAnchor.constraint(equalTo: theme.leadingAnchor, constant: -14),
            changeLanguageButton.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            changeLanguageButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 33),
            theme.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -8),
            theme.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            theme.widthAnchor.constraint(equalToConstant: 32),
            theme.heightAnchor.constraint(equalToConstant: 32)
        ])
        return bar
    }

    private func row(_ keys: [BoardKey], _ colors: BoardPalette) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 4
        stack.heightAnchor.constraint(equalToConstant: 48).isActive = true

        var firstButton: BoardButton?
        let reference = keys.first?.weight ?? 1
        for key in keys {
            let button = BoardButton(type: .custom)
            button.action = key.action
            button.layer.cornerRadius = 9
            button.layer.borderWidth = 0.5
            button.layer.borderColor = colors.border.cgColor
            let background = key.style == .function ? colors.utility :
                (key.style == .accent ? colors.accent : colors.key)
            button.standardBackground = background
            button.touchingBackground = colors.pressed
            button.backgroundColor = background
            button.setTitle(key.label, for: .normal)
            button.setTitleColor(key.style == .accent ? colors.background : colors.ink, for: .normal)
            button.titleLabel?.font = .systemFont(
                ofSize: key.style == .ordinary ? 19 : 13,
                weight: key.style == .ordinary ? .regular : .semibold
            )
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.65
            button.accessibilityLabel = accessibleName(key)
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            stack.addArrangedSubview(button)

            if let firstButton {
                button.widthAnchor.constraint(equalTo: firstButton.widthAnchor,
                                              multiplier: key.weight / reference).isActive = true
            } else {
                firstButton = button
            }
            if case .backspace = key.action {
                let press = UILongPressGestureRecognizer(target: self, action: #selector(heldDelete(_:)))
                press.minimumPressDuration = 0.4
                button.addGestureRecognizer(press)
            }
            if case .globe = key.action {
                button.removeTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
                button.addTarget(self, action: #selector(handleInputModeList(from:with:)),
                                 for: .allTouchEvents)
            }
        }
        return stack
    }

    private func accessibleName(_ key: BoardKey) -> String {
        switch key.action {
        case .text: key.label
        case .space: "Пробел"
        case .backspace: "Удалить"
        case .enter: "Ввод"
        case .shift: "Регистр и Caps Lock"
        case .language: "Переключить язык"
        case .numbers: "Цифры"
        case .symbols: "Символы"
        case .letters: "Буквы"
        case .globe: "Следующая клавиатура"
        }
    }

    private func characterKeys(_ characters: [String]) -> [BoardKey] {
        characters.map(BoardKey.character)
    }

    private func rows() -> [[BoardKey]] {
        let keyboardType = textDocumentProxy.keyboardType
        if keyboardType == .numberPad || keyboardType == .decimalPad ||
            keyboardType == .asciiCapableNumberPad {
            let separator = keyboardType == .decimalPad ? (Locale.current.decimalSeparator ?? ".") : "-"
            return [
                characterKeys(["1", "2", "3"]),
                characterKeys(["4", "5", "6"]),
                characterKeys(["7", "8", "9"]),
                [BoardKey.character(separator), BoardKey.character("0"),
                 .function("⌫", .backspace, weight: 1)]
            ]
        }

        switch page {
        case .letters:
            let layout = language == .ru
                ? ["йцукенгшщзхъ", "фывапролджэ", "ячсмитьбю"]
                : ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
            let caps = shift != .off
            let keyRows = layout.map { line in
                characterKeys(Array(line).map { caps ? String($0).uppercased() : String($0) })
            }
            var bottomLetters = [BoardKey.function(shift == .locked ? "⇪" : "⇧",
                                                    .shift, weight: 1.35)]
            bottomLetters += keyRows[2]
            bottomLetters.append(.function("⌫", .backspace, weight: 1.35))
            return [keyRows[0], keyRows[1], bottomLetters, bottomRow()]
        case .numbers:
            return [
                characterKeys(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]),
                characterKeys(["@", "#", "$", "%", "&", "-", "+", "(", ")", "/"]),
                [.function("=\\<", .symbols, weight: 1.35)] +
                    characterKeys(["*", "\"", ":", ";", "!", "?", "'"]) +
                    [.function("⌫", .backspace, weight: 1.35)],
                bottomRow()
            ]
        case .symbols:
            return [
                characterKeys(["~", "\u{0060}", "|", "•", "√", "π", "÷", "×", "¶", "Δ"]),
                characterKeys(["£", "€", "¥", "^", "°", "=", "{", "}", "\\", "©"]),
                [.function("123", .numbers, weight: 1.35)] +
                    characterKeys(["[", "]", "<", ">", "_", "…", "§"]) +
                    [.function("⌫", .backspace, weight: 1.35)],
                bottomRow()
            ]
        }
    }

    private func bottomRow() -> [BoardKey] {
        var keys = [BoardKey.function(page == .letters ? "123" : "ABC",
                                      page == .letters ? .numbers : .letters, weight: 1.4)]
        if needsInputModeSwitchKey {
            keys.append(.function("◎", .globe, weight: 0.85))
        }
        keys.append(.function(language.rawValue, .language, weight: 0.9))
        keys.append(.character(","))
        keys.append(BoardKey(label: language.space, action: .space, weight: 4.3, style: .space))
        keys.append(.character("."))
        keys.append(BoardKey(label: returnTitle(), action: .enter, weight: 1.4, style: .accent))
        return keys
    }

    private func returnTitle() -> String {
        switch textDocumentProxy.returnKeyType {
        case .send: "Отпр."
        case .search, .google, .yahoo: "Найти"
        case .go: "Перейти"
        case .done: "Готово"
        case .next: "Далее"
        default: "↵"
        }
    }

    @objc private func swapLanguage() {
        language = language == .ru ? .en : .ru
        UserDefaults.standard.set(language.rawValue, forKey: "keyboard.language")
        page = .letters
        adjustShift()
        render()
    }

    @objc private func swapTheme() {
        customTheme = !dark
        UserDefaults.standard.set(customTheme!, forKey: "keyboard.dark")
        render()
    }

    @objc private func tapped(_ sender: BoardButton) {
        switch sender.action {
        case .text(let text):
            textDocumentProxy.insertText(text)
            if page == .letters && shift == .once {
                shift = .off
                render()
            }
        case .space:
            textDocumentProxy.insertText(" ")
            adjustShift()
            render()
        case .backspace:
            textDocumentProxy.deleteBackward()
            adjustShift()
            render()
        case .enter:
            textDocumentProxy.insertText("\n")
            adjustShift()
            render()
        case .shift:
            let now = Date().timeIntervalSince1970
            if shift == .once && now - lastShiftTap < 0.4 {
                shift = .locked
            } else if shift == .off {
                shift = .once
            } else {
                shift = .off
            }
            lastShiftTap = now
            render()
        case .language: swapLanguage()
        case .numbers: page = .numbers; render()
        case .symbols: page = .symbols; render()
        case .letters: page = .letters; render()
        case .globe: advanceToNextInputMode()
        }
    }

    private func adjustShift() {
        guard shift != .locked else { return }
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let startsSentence = context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            context.range(of: "[.!?]\\s*$", options: .regularExpression) != nil
        if startsSentence { shift = .once }
    }

    @objc private func heldDelete(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            deleteTimer?.invalidate()
            textDocumentProxy.deleteBackward()
            deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in
                self?.textDocumentProxy.deleteBackward()
            }
        case .ended, .cancelled, .failed:
            deleteTimer?.invalidate()
            deleteTimer = nil
            adjustShift()
            render()
        default: break
        }
    }
}
