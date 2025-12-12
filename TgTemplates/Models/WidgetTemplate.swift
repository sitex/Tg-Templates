import Foundation

struct WidgetTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let messageText: String
    let targetGroupId: Int64?
    let targetGroupName: String?
    let includeLocation: Bool
}
