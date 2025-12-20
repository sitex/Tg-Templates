import SwiftUI
import SwiftData
import WidgetKit

@main
struct TgTemplatesApp: App {

    init() {
        // Initialize WatchConnectivity early
        _ = WatchConnectivityManager.shared

        if TelegramConfig.isConfigured {
            TelegramService.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Template.self])
    }
}

extension Notification.Name {
    static let sendTemplate = Notification.Name("sendTemplate")
}
