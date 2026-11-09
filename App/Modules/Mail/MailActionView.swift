import SwiftUI
import MessageUI
import Network

/// IMAP4 over TLS. Only reads STATUS metadata; never downloads message bodies.
private final class IMAPStatusProbe {
    private let queue = DispatchQueue(label: "io.github.allinoneipa.imap")

    func check(host: String, port: UInt16, user: String, password: String) async throws -> String {
        guard !host.isEmpty, !user.isEmpty, !password.isEmpty,
              !user.contains("\n"), !password.contains("\n"),
              !user.contains("\r"), !password.contains("\r") else {
            throw ModuleOperationError("Укажи IMAP-сервер, логин и пароль.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            let parameters = NWParameters(tls: NWProtocolTLS.Options(), tcp: NWProtocolTCP.Options())
            let connection = NWConnection(host: NWEndpoint.Host(host),
                                          port: NWEndpoint.Port(rawValue: port)!, using: parameters)
            var completed = false
            var phase = 0
            var buffer = ""
            var mailbox = "Нет ответа"
            func finish(_ outcome: Result<String, Error>) {
                guard !completed else { return }
                completed = true
                connection.cancel()
                continuation.resume(with: outcome)
            }
            func quote(_ input: String) -> String {
                input.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
            }
            func write(_ line: String) {
                connection.send(content: Data(line.utf8), completion: .contentProcessed { error in
                    if let error { self.queue.async { finish(.failure(error)) } }
                })
            }
            func handleLine(_ line: String) {
                if phase == 0 {
                    if line.hasPrefix("* OK") || line.hasPrefix("* PREAUTH") {
                        phase = 1
                        write("A001 LOGIN \"\(quote(user))\" \"\(quote(password))\"\r\n")
                    } else if line.hasPrefix("* BYE") {
                        finish(.failure(ModuleOperationError("IMAP-сервер отклонил соединение.")))
                    }
                } else if phase == 1, line.hasPrefix("A001 ") {
                    if line.uppercased().hasPrefix("A001 OK") {
                        phase = 2
                        write("A002 STATUS INBOX (MESSAGES UNSEEN)\r\n")
                    } else {
                        finish(.failure(ModuleOperationError("IMAP отклонил логин.")))
                    }
                } else if phase == 2 {
                    if line.uppercased().hasPrefix("* STATUS ") {
                        mailbox = line
                    } else if line.uppercased().hasPrefix("A002 ") {
                        if line.uppercased().hasPrefix("A002 OK") {
                            write("A003 LOGOUT\r\n")
                            finish(.success(mailbox))
                        } else {
                            finish(.failure(ModuleOperationError("Не удалось прочитать статус INBOX.")))
                        }
                    }
                }
            }
            func receive() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) {
                    data, _, done, error in
                    self.queue.async {
                        guard !completed else { return }
                        if let error { finish(.failure(error)); return }
                        if let data {
                            buffer += String(decoding: data, as: UTF8.self)
                            guard buffer.count < 100_000 else {
                                finish(.failure(ModuleOperationError("Превышен размер IMAP-ответа.")))
                                return
                            }
                            while let range = buffer.range(of: "\r\n") {
                                let line = String(buffer[..<range.lowerBound])
                                buffer.removeSubrange(buffer.startIndex..<range.upperBound)
                                handleLine(line)
                                if completed { return }
                            }
                        }
                        if done {
                            finish(.failure(ModuleOperationError("IMAP-соединение закрыто.")))
                        } else {
                            receive()
                        }
                    }
                }
            }

            connection.stateUpdateHandler = { state in
                self.queue.async {
                    switch state {
                    case .ready: receive()
                    case .failed(let error): finish(.failure(error))
                    case .cancelled:
                        if !completed {
                            finish(.failure(ModuleOperationError("Соединение отменено.")))
                        }
                    default: break
                    }
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 20) {
                finish(.failure(ModuleOperationError("Тайм-аут IMAP (20 секунд).")))
            }
        }
    }
}

private struct NativeMailComposer: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let message: String
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: { dismiss() }) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipient.isEmpty ? [] : [recipient])
        controller.setSubject(subject)
        controller.setMessageBody(message, isHTML: false)
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: () -> Void
        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

struct MailActionView: View {
    @Binding var values: [String: String]
    @State private var password = ""
    @State private var recipient = ""
    @State private var subject = ""
    @State private var bodyText = ""
    @State private var status = ""
    @State private var failed = false
    @State private var busy = false
    @State private var compose = false

    var body: some View {
        VStack(spacing: 13) {
            ModuleActionCard(title: "IMAP: состояние ящика", symbol: "envelope.badge") {
                Text("Проверка INBOX через IMAPS/TLS: количество писем и непрочитанных. Содержимое писем не загружается.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ModuleField(title: "Пароль почтового ящика", placeholder: "Пароль приложения / IMAP",
                            value: $password, secure: true)
                ModuleRunButton(title: "Проверить входящие", symbol: "envelope.open", busy: busy) {
                    Task { await check() }
                }
                if !status.isEmpty { ModuleResponse(value: status, failed: failed) }
            }

            ModuleActionCard(title: "Отправить письмо", symbol: "paperplane.fill") {
                ModuleField(title: "Кому", placeholder: "contact@example.com", value: $recipient)
                ModuleField(title: "Тема", placeholder: "Тема письма", value: $subject)
                TextEditor(text: $bodyText)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .frame(height: 100)
                    .padding(7)
                    .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))

                ModuleRunButton(title: "Открыть редактор письма", symbol: "square.and.pencil") {
                    openComposer()
                }
                Text("Отправка выполняется через системный почтовый редактор iOS. Приложение не отправляет письма без подтверждения.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.secondary)
            }
        }
        .sheet(isPresented: $compose) {
            NativeMailComposer(recipient: recipient, subject: subject, message: bodyText)
        }
    }

    @MainActor
    private func check() async {
        busy = true
        defer { busy = false }
        let hostname = (values["incoming"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let port = UInt16(values["incomingPort"] ?? "993") ?? 993
        let user = values["address"] ?? ""
        do {
            let response = try await IMAPStatusProbe().check(host: hostname, port: port,
                                                              user: user, password: password)
            status = response
            failed = false
        } catch {
            status = error.localizedDescription
            failed = true
        }
    }

    private func openComposer() {
        if MFMailComposeViewController.canSendMail() {
            compose = true
            return
        }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: bodyText)
        ]
        if let url = components.url {
            UIApplication.shared.open(url)
        } else {
            status = "Не удалось открыть почтовое приложение."
            failed = true
        }
    }
}
