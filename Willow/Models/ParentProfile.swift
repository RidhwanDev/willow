import Foundation
import SwiftData

@Model
final class ParentProfile {
    var id: UUID
    var name: String
    var companionName: String
    var companionType: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        companionName: String,
        companionType: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.companionName = companionName
        self.companionType = companionType
        self.createdAt = createdAt
    }
}
