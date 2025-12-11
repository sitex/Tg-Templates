import AppIntents
import Foundation

struct SendTemplateIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Template"
    static var description = IntentDescription("Sends a template message to Telegram")

    @Parameter(title: "Template ID")
    var templateId: String

    static var openAppWhenRun: Bool = true

    init() {
        self.templateId = ""
    }

    init(templateId: UUID) {
        self.templateId = templateId.uuidString
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        // The app will be opened automatically due to openAppWhenRun = true
        // The URL scheme will be handled by the main app
        guard let url = URL(string: "tgtemplates://send?id=\(templateId)") else {
            return .result()
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}
