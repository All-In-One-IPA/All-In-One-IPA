import SwiftUI

/// A reusable functional foundation for each planned module.
///
/// Values are saved only when the user chooses "Save". Never store credentials
/// in this view: future secure storage belongs in a Keychain-backed service.
struct ModuleWorkspaceView: View {
    let module: ModuleInfo
    let blueprint: ModuleBlueprint

    @State private var values: [String: String] = [:]
    @State private var saved = false
    @State private var validation: String?
    @State private var confirmReset = false

    init(module: ModuleInfo, blueprint: ModuleBlueprint) {
        self.module = module
        self.blueprint = blueprint
    }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if module.id == "network" {
                        HTTPDiagnosticView()
                    }
                    forEachGroups
                    saveControls
                    milestones
                    privacy
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 35)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .confirmationDialog("Удалить сохранённые настройки?", isPresented: $confirmReset) {
            Button("Удалить настройки", role: .destructive, action: reset)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Будут удалены только настройки этого модуля на устройстве.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ModuleGlyph(module: module, size: 70)
                Spacer()
                StatusPill(status: module.status)
            }

            Text(blueprint.headline)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.ink)

            Text(blueprint.description)
                .font(.system(size: 13))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .surfaceCard(radius: 25)
    }

    private var forEachGroups: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(title: "Конфигурация")
            ForEach(blueprint.groups) { group in
                VStack(alignment: .leading, spacing: 15) {
                    Text(group.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.ink)

                    ForEach(group.inputs) { input in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(input.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Palette.secondary)
                            field(input)
                        }
                    }
                }
                .padding(17)
                .frame(maxWidth: .infinity, alignment: .leading)
                .surfaceCard(radius: 20)
            }
        }
    }

    @ViewBuilder
    private func field(_ input: ModuleInput) -> some View {
        switch input.kind {
        case .options(let options):
            Picker(input.title, selection: binding(for: input)) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Palette.cyan)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .port:
            TextField(input.placeholder, text: binding(for: input))
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .modifier(ModuleTextFieldStyle())
        case .url:
            TextField(input.placeholder, text: binding(for: input))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .modifier(ModuleTextFieldStyle())
        case .hostname:
            TextField(input.placeholder, text: binding(for: input))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .modifier(ModuleTextFieldStyle())
        case .text:
            TextField(input.placeholder, text: binding(for: input))
                .modifier(ModuleTextFieldStyle())
        }
    }

    private func binding(for field: ModuleInput) -> Binding<String> {
        Binding(
            get: { values[field.id] ?? field.initialValue },
            set: { values[field.id] = $0; saved = false; validation = nil }
        )
    }

    private var saveControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: save) {
                HStack(spacing: 9) {
                    Image(systemName: "checkmark.circle")
                    Text("Сохранить настройки")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Palette.cyan, in: RoundedRectangle(cornerRadius: 17))
            }
            .buttonStyle(.plain)

            if saved {
                Label("Сохранено только на этом iPhone", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.green)
            }

            if let validation {
                Text(validation)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.coral)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Сбросить настройки", role: .destructive) {
                confirmReset = true
            }
            .font(.system(size: 12, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.top, 3)
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "Следующие этапы")
            ForEach(Array(blueprint.milestones.enumerated()), id: \.offset) { index, milestone in
                HStack(alignment: .top, spacing: 13) {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(module.category.tint)
                        .frame(width: 25)
                    Text(milestone)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(15)
                .surfaceCard(radius: 16)
            }
        }
    }

    private var privacy: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 17))
                .foregroundStyle(Palette.green)
            Text(blueprint.privacyNotice)
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard(radius: 18)
    }

    private var storageKey: String { "module.configuration.\(module.id).v1" }

    private func load() {
        let stored = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] ?? [:]
        values = Dictionary(uniqueKeysWithValues:
            blueprint.allInputs.map { ($0.id, stored[$0.id] ?? $0.initialValue) })
        saved = false
        validation = nil
    }

    private func save() {
        for input in blueprint.allInputs {
            if case .port = input.kind {
                let raw = values[input.id] ?? input.initialValue
                guard let port = Int(raw), (1...65535).contains(port) else {
                    validation = "Поле «\(input.title)»: укажи число от 1 до 65535."
                    return
                }
            }
        }
        UserDefaults.standard.set(values, forKey: storageKey)
        saved = true
        validation = nil
    }

    private func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        values = Dictionary(uniqueKeysWithValues:
            blueprint.allInputs.map { ($0.id, $0.initialValue) })
        saved = false
        validation = nil
    }
}

private struct ModuleTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Palette.hairline.opacity(0.65), lineWidth: 0.8)
            }
    }
}
