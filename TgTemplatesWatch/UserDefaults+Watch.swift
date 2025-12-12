import Foundation

extension UserDefaults {
    static let watchGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    var widgetTemplates: [WidgetTemplate] {
        get {
            guard let data = data(forKey: "widgetTemplates"),
                  let templates = try? JSONDecoder().decode([WidgetTemplate].self, from: data) else {
                return []
            }
            return templates
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: "widgetTemplates")
        }
    }
}
