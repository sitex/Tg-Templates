import SwiftUI

struct TemplateDetailView: View {
    let template: WidgetTemplate
    @ObservedObject private var connectivity = WatchConnectivityManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Icon and name
                VStack(spacing: 8) {
                    Image(systemName: template.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)

                    Text(template.name)
                        .font(.headline)
                }
                .padding(.top)

                // Message preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(template.messageText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                // Target group
                if let groupName = template.targetGroupName {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Send to")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(groupName)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }

                // Location indicator
                if template.includeLocation {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                        Text("Includes location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Send button
                Button {
                    connectivity.sendTemplate(id: template.id)
                } label: {
                    switch connectivity.sendStatus {
                    case .idle:
                        Label("Send", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    case .sending:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    case .success:
                        Label("Sent!", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    case .error:
                        Label("Failed", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(buttonTint)
                .disabled(connectivity.sendStatus == .sending)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            connectivity.sendStatus = .idle
        }
    }

    private var buttonTint: Color {
        switch connectivity.sendStatus {
        case .success: return .green
        case .error: return .red
        default: return .accentColor
        }
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(template: WidgetTemplate(
            id: UUID(),
            name: "Good Morning",
            icon: "sun.max.fill",
            messageText: "Good morning everyone! Hope you have a great day!",
            targetGroupId: nil,
            targetGroupName: "Family Chat",
            includeLocation: true
        ))
    }
}
