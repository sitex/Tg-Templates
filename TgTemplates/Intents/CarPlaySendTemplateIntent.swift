import AppIntents
import Foundation

@available(iOS 16.0, *)
struct CarPlaySendTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Template"
    static var description = IntentDescription("Send a Telegram template message")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Template")
    var templateName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Send \(\.$templateName)")
    }

    init() {}

    init(templateName: String) {
        self.templateName = templateName
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Find template by name
        let templates = UserDefaults.appGroup.widgetTemplates

        guard let template = templates.first(where: {
            $0.name.lowercased() == templateName.lowercased()
        }) else {
            return .result(dialog: "Template '\(templateName)' not found")
        }

        // Check if TelegramService is ready
        guard TelegramService.shared.isReady else {
            return .result(dialog: "Please open TgTemplates to log in first")
        }

        // Send the template
        do {
            try await TelegramService.shared.sendTemplateMessage(template)
            return .result(dialog: "Sent \(template.name)!")
        } catch {
            return .result(dialog: "Failed to send: \(error.localizedDescription)")
        }
    }
}
