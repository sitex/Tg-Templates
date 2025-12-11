import Foundation
import SwiftData

@Model
final class Template {
    var id: UUID
    var name: String
    var icon: String
    var messageText: String
    var targetGroupId: Int64?
    var targetGroupName: String?
    var includeLocation: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    init(
        name: String,
        icon: String = "paperplane.fill",
        messageText: String,
        targetGroupId: Int64? = nil,
        targetGroupName: String? = nil,
        includeLocation: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.messageText = messageText
        self.targetGroupId = targetGroupId
        self.targetGroupName = targetGroupName
        self.includeLocation = includeLocation
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }
}
