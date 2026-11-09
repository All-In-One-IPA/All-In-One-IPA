import SwiftUI

enum DeviceKind: String, CaseIterable, Codable, Identifiable {
    case ssh, beszel, web

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ssh: "SSH / SFTP"
        case .beszel: "Beszel"
        case .web: "Web API"
        }
    }

    var symbol: String {
        switch self {
        case .ssh: "terminal"
        case .beszel: "chart.bar.xaxis"
        case .web: "globe"
        }
    }
}

struct SavedDevice: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var kind: DeviceKind
}

struct DevicesView: View {
    @AppStorage("devices.v1") private var persistedDevices: String = "[]"
    @State private var showingAdd = false

    private var devices: [SavedDevice] {
        guard let data = persistedDevices.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedDevice].self, from: data) else {
            return []
        }
        return decoded
    }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 7) {
                            Eyebrow(text: "ПОДКЛЮЧЕНИЯ")
                            Text("Устройства")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Text("Твои серверы и удалённые службы.")
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.secondary)
                        }
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Palette.background)
                                .frame(width: 43, height: 43)
                                .background(Palette.cyan, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel("Добавить устройство")
                    }

                    if devices.isEmpty {
                        QuietEmptyState(
                            symbol: "externaldrive.badge.plus",
                            title: "Пока пусто",
                            message: "Можно сохранить адреса своих серверов. Подключение по SSH, Beszel и HTTP появится в следующих версиях."
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 13) {
                            SectionHeading(title: "Сохранённые", trailing: nil, action: nil)
                            ForEach(devices) { device in
                                NavigationLink {
                                    DeviceInfoView(device: device)
                                } label: {
                                    HStack(spacing: 13) {
                                        Image(systemName: device.kind.symbol)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(Palette.green)
                                            .frame(width: 50, height: 50)
                                            .background(Palette.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(device.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(Palette.ink)
                                            Text(device.host)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundStyle(Palette.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Palette.secondary)
                                    }
                                    .padding(15)
                                    .surfaceCard(radius: 20)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(device.id)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Palette.cyan)
                        Text("На этом этапе сохраняются только названия и адреса. Соединения ещё не выполняются; пароли и ключи не запрашиваются.")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                }
                .padding(.horizontal, 20)
                .padding(.top, 17)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            AddDeviceSheet { device in
                var updated = devices
                updated.append(device)
                persist(updated)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func persist(_ updated: [SavedDevice]) {
        guard let data = try? JSONEncoder().encode(updated),
              let string = String(data: data, encoding: .utf8) else { return }
        persistedDevices = string
    }

    private func delete(_ id: UUID) {
        persist(devices.filter { $0.id != id })
    }
}

struct AddDeviceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var kind: DeviceKind = .ssh
    let onSave: (SavedDevice) -> Void

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Подключение") {
                    TextField("Название", text: $name)
                    TextField("Адрес или домен", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Тип", selection: $kind) {
                        ForEach(DeviceKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                }
                Section {
                    Text("Сохраняется только карточка. Настоящее подключение появится позднее.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Новое устройство")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(SavedDevice(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                           host: host.trimmingCharacters(in: .whitespacesAndNewlines),
                                           kind: kind))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

struct DeviceInfoView: View {
    let device: SavedDevice

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Image(systemName: device.kind.symbol)
                        .font(.system(size: 30))
                        .foregroundStyle(Palette.green)
                        .frame(width: 75, height: 75)
                        .background(Palette.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
                    Text(device.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(device.host)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Palette.secondary)
                        .textSelection(.enabled)
                    Text(device.kind.title)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.green)
                    QuietEmptyState(symbol: "powerplug", title: "Подключение ещё не готово",
                                    message: "Адрес сохранён на устройстве. После реализации сетевых модулей здесь появятся параметры и кнопка подключения.")
                        .padding(.top, 22)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .navigationTitle("Устройство")
        .navigationBarTitleDisplayMode(.inline)
    }
}
