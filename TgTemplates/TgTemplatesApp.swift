import SwiftUI
import SwiftData

@main
struct TgTemplatesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Template.self])
    }
}
