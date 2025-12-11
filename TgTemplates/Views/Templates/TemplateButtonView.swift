import SwiftUI

struct TemplateButtonView: View {
    let template: Template
    let onLongPress: () -> Void

    @ObservedObject var telegram = TelegramService.shared
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Button {
            sendMessage()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    if isSending {
                        ProgressView()
                    } else if showSuccess {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }

                Text(template.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            onLongPress()
        }
        .sensoryFeedback(.success, trigger: showSuccess)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func sendMessage() {
        guard template.targetGroupId != nil else {
            errorMessage = "No group selected"
            showError = true
            return
        }

        isSending = true

        Task {
            do {
                try await telegram.sendTemplateMessage(template)
                showSuccess = true
                try await Task.sleep(for: .seconds(1))
                showSuccess = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSending = false
        }
    }
}
