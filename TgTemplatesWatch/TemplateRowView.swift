import SwiftUI

struct TemplateRowView: View {
    let template: WidgetTemplate

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: template.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)

                if let groupName = template.targetGroupName {
                    Text(groupName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TemplateRowView(template: WidgetTemplate(
        id: UUID(),
        name: "Good Morning",
        icon: "sun.max.fill",
        messageText: "Good morning!",
        targetGroupId: nil,
        targetGroupName: "Family Chat",
        includeLocation: false
    ))
}
