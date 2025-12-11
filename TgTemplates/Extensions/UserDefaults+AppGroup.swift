import Foundation

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.sitex.TgTemplates")!

    private enum Keys {
        static let cachedGroups = "cachedGroups"
        static let widgetTemplates = "widgetTemplates"
    }

    var cachedGroups: [TelegramGroup] {
        get {
            guard let data = data(forKey: Keys.cachedGroups),
                  let groups = try? JSONDecoder().decode([TelegramGroup].self, from: data) else {
                return []
            }
            return groups
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: Keys.cachedGroups)
        }
    }

    var widgetTemplates: [WidgetTemplate] {
        get {
            guard let data = data(forKey: Keys.widgetTemplates),
                  let templates = try? JSONDecoder().decode([WidgetTemplate].self, from: data) else {
                return []
            }
            return templates
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: Keys.widgetTemplates)
        }
    }
}
