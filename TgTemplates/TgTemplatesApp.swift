import SwiftUI
import SwiftData

@main
struct TgTemplatesApp: App {
    @StateObject private var telegram = TelegramService.shared

    var body: some Scene {
        WindowGroup {
            if telegram.isReady {
                ContentView()
            } else {
                AuthView()
            }
        }
        .modelContainer(for: [Template.self])
    }

    init() {
        TelegramService.shared.start()
    }
}
