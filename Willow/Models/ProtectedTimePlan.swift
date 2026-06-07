import Foundation
import SwiftData

@Model
final class ProtectedTimePlan {
    var id: UUID
    var parentId: UUID
    var protectedByParentId: UUID?
    var title: String
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        parentId: UUID,
        protectedByParentId: UUID? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.parentId = parentId
        self.protectedByParentId = protectedByParentId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
