import Foundation

extension UserDefaults {
    static let watchGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    var widgetTemplates: [WidgetTemplate] {
        guard let data = data(forKey: "widgetTemplates"),
              let templates = try? JSONDecoder().decode([WidgetTemplate].self, from: data) else {
            return []
        }
        return templates
    }
}
