import SwiftUI
import AppIntents

struct TemplateDetailView: View {
    let template: WidgetTemplate

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
                Button(intent: WatchSendTemplateIntent(templateId: template.id)) {
                    Label("Send", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
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
