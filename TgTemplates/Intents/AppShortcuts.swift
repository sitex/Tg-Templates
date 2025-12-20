import AppIntents

@available(iOS 16.0, *)
struct TgTemplatesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CarPlaySendTemplateIntent(),
            phrases: [
                "Send \(\.$templateName) with \(.applicationName)",
                "Send \(\.$templateName) template",
                "\(.applicationName) send \(\.$templateName)"
            ],
            shortTitle: "Send Template",
            systemImageName: "paperplane.fill"
        )
    }
}
