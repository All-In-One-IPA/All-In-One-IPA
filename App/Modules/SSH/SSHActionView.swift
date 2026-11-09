import SwiftUI
import Citadel

/// Real SSH exec and read-only SFTP listing over encrypted SSH.
struct SSHActionView: View {
    @Binding var values: [String: String]
    @State private var password = ""
    @State private var command = "uname -a"
    @State private var remotePath = "."
    @State private var acknowledge = false
    @State private var busy = false
    @State private var output = ""
    @State private var failed = false

    var body: some View {
        ModuleActionCard(title: "SSH / SFTP", symbol: "terminal.fill") {
            ModuleField(title: "Пароль SSH (не сохраняется)", placeholder: "Пароль",
                        value: $password, secure: true)
            ModuleField(title: "Команда", placeholder: "uname -a", value: $command)
            ModuleField(title: "Папка SFTP", placeholder: ".", value: $remotePath)

            Toggle("Понимаю: проверка ключа хоста пока не реализована", isOn: $acknowledge)
                .font(.system(size: 11))
                .tint(Palette.cyan)

            Text("Шифрование SSH работает, но до добавления known_hosts подлинность сервера не проверяется. Не используй для важных серверов в недоверенной сети.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ModuleRunButton(title: "Выполнить команду", symbol: "terminal", busy: busy) {
                Task { await perform(.command) }
            }
            ModuleRunButton(title: "Открыть папку по SFTP", symbol: "folder", busy: busy) {
                Task { await perform(.sftp) }
            }
            if !output.isEmpty { ModuleResponse(value: output, failed: failed) }
        }
        .onAppear {
            remotePath = values["startPath"] ?? "."
        }
    }

    private enum Operation { case command, sftp }

    @MainActor
    private func perform(_ operation: Operation) async {
        guard acknowledge else {
            failed = true
            output = "Для тестового подключения подтверди предупреждение о проверке ключа хоста."
            return
        }
        let host = (values["host"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let username = values["username"] ?? "root"
        guard !host.isEmpty, !username.isEmpty, !password.isEmpty,
              let port = Int(values["port"] ?? "22"), (1...65535).contains(port) else {
            failed = true
            output = "Укажи хост, порт, имя пользователя и пароль."
            return
        }

        busy = true
        failed = false
        output = "Подключение к \(host)..."
        defer { busy = false }

        do {
            let capturedPassword = password
            let settings = SSHClientSettings(
                host: host, port: port,
                authenticationMethod: { .passwordBased(username: username, password: capturedPassword) },
                hostKeyValidator: .acceptAnything()
            )
            let client = try await SSHClient.connect(to: settings)
            defer { Task { try? await client.close() } }

            switch operation {
            case .command:
                let response = try await client.executeCommand(command, maxResponseSize: 512_000,
                                                               mergeStreams: true)
                let value = String(decoding: response.readableBytesView, as: UTF8.self)
                output = value.isEmpty ? "Команда выполнена; вывод пуст." : value
            case .sftp:
                let clientSFTP = try await client.openSFTP()
                defer { Task { try? await clientSFTP.close() } }
                let directory = try await clientSFTP.listDirectory(atPath: remotePath)
                let names = directory.flatMap { $0.components.map { $0.filename } }
                output = names.isEmpty ? "Папка пуста." : names.joined(separator: "\n")
            }
        } catch {
            failed = true
            output = "SSH/SFTP: \(error.localizedDescription)"
        }
    }
}
