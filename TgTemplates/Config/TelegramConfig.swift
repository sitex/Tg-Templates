import Foundation

// Telegram API credentials stored in UserDefaults
// Get your API credentials from https://my.telegram.org
enum TelegramConfig {
    private static let apiIdKey = "telegram_api_id"
    private static let apiHashKey = "telegram_api_hash"

    static var apiId: Int32 {
        get { Int32(UserDefaults.standard.integer(forKey: apiIdKey)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: apiIdKey) }
    }

    static var apiHash: String {
        get { UserDefaults.standard.string(forKey: apiHashKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiHashKey) }
    }

    static var isConfigured: Bool {
        apiId != 0 && !apiHash.isEmpty
    }
}
