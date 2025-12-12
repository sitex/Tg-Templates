import AppIntents
import Foundation

struct WatchSendTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Template from Watch"
    static var description = IntentDescription("Sends a template message to Telegram via iPhone")

    @Parameter(title: "Template ID")
    var templateId: String

    static var openAppWhenRun: Bool = true

    init() {
        self.templateId = ""
    }

    init(templateId: UUID) {
        self.templateId = templateId.uuidString
    }

    func perform() async throws -> some IntentResult {
        // Store the template ID for the iPhone app to read when it opens
        UserDefaults(suiteName: "group.com.sitex.TgTemplates")?.set(templateId, forKey: "pendingTemplateId")
        return .result()
    }
}
