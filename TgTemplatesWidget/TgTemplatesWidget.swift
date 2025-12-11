import WidgetKit
import SwiftUI

// UserDefaults extension for widget (same App Group as main app)
extension UserDefaults {
    static let widgetGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    var widgetTemplates: [WidgetTemplate] {
        get {
            guard let data = data(forKey: "widgetTemplates"),
                  let templates = try? JSONDecoder().decode([WidgetTemplate].self, from: data) else {
                return []
            }
            return templates
        }
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TemplateEntry {
        TemplateEntry(date: Date(), templates: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TemplateEntry) -> Void) {
        let templates = UserDefaults.widgetGroup.widgetTemplates
        completion(TemplateEntry(date: Date(), templates: Array(templates.prefix(4))))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TemplateEntry>) -> Void) {
        let templates = UserDefaults.widgetGroup.widgetTemplates
        let entry = TemplateEntry(date: Date(), templates: Array(templates.prefix(4)))
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct TemplateEntry: TimelineEntry {
    let date: Date
    let templates: [WidgetTemplate]
}

struct TgTemplatesWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.templates.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("No templates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            default:
                mediumWidget
            }
        }
    }

    @ViewBuilder
    var smallWidget: some View {
        if let first = entry.templates.first {
            Button(intent: SendTemplateIntent(templateId: first.id)) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: first.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    Text(first.name)
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .buttonStyle(.plain)
        } else {
            Text("Add template")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    var mediumWidget: some View {
        HStack(spacing: 16) {
            ForEach(entry.templates.prefix(4)) { template in
                Button(intent: SendTemplateIntent(templateId: template.id)) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: template.icon)
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        Text(template.name)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

@main
struct TgTemplatesWidget: Widget {
    let kind: String = "TgTemplatesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TgTemplatesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Templates")
        .description("Quick access to your Telegram templates")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TgTemplatesWidget()
} timeline: {
    TemplateEntry(date: .now, templates: [
        WidgetTemplate(
            id: UUID(),
            name: "Test",
            icon: "paperplane.fill",
            messageText: "Hello",
            targetGroupId: nil,
            targetGroupName: nil,
            includeLocation: false
        )
    ])
}

#Preview(as: .systemMedium) {
    TgTemplatesWidget()
} timeline: {
    TemplateEntry(date: .now, templates: [
        WidgetTemplate(
            id: UUID(),
            name: "Work",
            icon: "briefcase.fill",
            messageText: "At work",
            targetGroupId: nil,
            targetGroupName: nil,
            includeLocation: false
        ),
        WidgetTemplate(
            id: UUID(),
            name: "Home",
            icon: "house.fill",
            messageText: "At home",
            targetGroupId: nil,
            targetGroupName: nil,
            includeLocation: false
        ),
        WidgetTemplate(
            id: UUID(),
            name: "Lunch",
            icon: "fork.knife",
            messageText: "Lunch time",
            targetGroupId: nil,
            targetGroupName: nil,
            includeLocation: false
        )
    ])
}
