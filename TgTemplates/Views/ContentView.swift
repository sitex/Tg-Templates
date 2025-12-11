import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var templates: [Template]
    @ObservedObject var telegram = TelegramService.shared

    @State private var sendingTemplateId: UUID?
    @State private var showSendSuccess = false
    @State private var showSendError = false
    @State private var sendErrorMessage = ""

    var body: some View {
        TemplateListView()
            .onReceive(NotificationCenter.default.publisher(for: .sendTemplate)) { notification in
                guard let userInfo = notification.userInfo,
                      let templateId = userInfo["templateId"] as? UUID else {
                    return
                }
                sendTemplateFromWidget(templateId: templateId)
            }
            .overlay {
                if sendingTemplateId != nil {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Sending...")
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                }
            }
            .sensoryFeedback(.success, trigger: showSendSuccess)
            .alert("Message Sent", isPresented: $showSendSuccess) {
                Button("OK") {}
            }
            .alert("Error", isPresented: $showSendError) {
                Button("OK") {}
            } message: {
                Text(sendErrorMessage)
            }
    }

    private func sendTemplateFromWidget(templateId: UUID) {
        guard let template = templates.first(where: { $0.id == templateId }) else {
            sendErrorMessage = "Template not found"
            showSendError = true
            return
        }

        sendingTemplateId = templateId

        Task {
            do {
                try await telegram.sendTemplateMessage(template)
                sendingTemplateId = nil
                showSendSuccess = true
            } catch {
                sendingTemplateId = nil
                sendErrorMessage = error.localizedDescription
                showSendError = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Template.self, inMemory: true)
}
