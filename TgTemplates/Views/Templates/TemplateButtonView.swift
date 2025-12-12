import SwiftUI

struct TemplateButtonView: View {
    let template: Template
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

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
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
