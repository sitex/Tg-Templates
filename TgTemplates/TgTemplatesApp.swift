import SwiftUI
import SwiftData
import WidgetKit

@main
struct TgTemplatesApp: App {
    @StateObject private var telegram = TelegramService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var isConfigured = TelegramConfig.isConfigured

    var body: some Scene {
        WindowGroup {
            if !isConfigured {
                ApiConfigView(isConfigured: $isConfigured)
            } else if telegram.isReady {
                ContentView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onAppear {
                        checkPendingTemplate()
                    }
            } else {
                AuthView()
            }
        }
        .modelContainer(for: [Template.self])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkPendingTemplate()
            }
        }
        .onChange(of: isConfigured) { _, configured in
            if configured {
                TelegramService.shared.start()
            }
        }
    }

    init() {
        if TelegramConfig.isConfigured {
            TelegramService.shared.start()
        }
    }

    private func checkPendingTemplate() {
        let defaults = UserDefaults(suiteName: "group.com.sitex.TgTemplates")
        guard let idString = defaults?.string(forKey: "pendingTemplateId"),
              let templateId = UUID(uuidString: idString) else {
            return
        }

        // Clear the pending template
        defaults?.removeObject(forKey: "pendingTemplateId")

        // Post notification to send template
        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
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
