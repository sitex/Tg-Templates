import SwiftUI
import SwiftData

struct RootView: View {
    @StateObject private var telegram = TelegramService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var isConfigured = TelegramConfig.isConfigured

    var body: some View {
        Group {
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

    private func checkPendingTemplate() {
        let defaults = UserDefaults(suiteName: "group.com.sitex.TgTemplates")
        guard let idString = defaults?.string(forKey: "pendingTemplateId"),
              let templateId = UUID(uuidString: idString) else {
            return
        }

        defaults?.removeObject(forKey: "pendingTemplateId")

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

        NotificationCenter.default.post(
            name: .sendTemplate,
            object: nil,
            userInfo: ["templateId": templateId]
        )
    }
}
