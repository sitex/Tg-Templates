import SwiftUI
import SwiftData
import WidgetKit

@main
struct TgTemplatesApp: App {
    @StateObject private var telegram = TelegramService.shared

    var body: some Scene {
        WindowGroup {
            if telegram.isReady {
                ContentView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                AuthView()
            }
        }
        .modelContainer(for: [Template.self])
    }

    init() {
        TelegramService.shared.start()
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tgtemplates",
              url.host == "send",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let templateId = UUID(uuidString: idString) else {
            return
        }

        // Post notification to send template
        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
    }
}

extension Notification.Name {
    static let sendTemplate = Notification.Name("sendTemplate")
}
