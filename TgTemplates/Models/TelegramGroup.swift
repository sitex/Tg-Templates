import Foundation

struct TelegramGroup: Identifiable, Codable, Hashable {
    let id: Int64
    let title: String
    let memberCount: Int

    var displayTitle: String {
        "\(title) (\(memberCount) members)"
    }
}
