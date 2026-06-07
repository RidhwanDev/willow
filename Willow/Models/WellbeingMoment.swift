import Foundation
import SwiftData

@Model
final class WellbeingMoment {
    var id: UUID
    var parentId: UUID
    var type: MomentType
    var title: String
    var date: Date
    var durationMinutes: Int
    var timeQuality: TimeQuality
    var notes: String?

    init(
        id: UUID = UUID(),
        parentId: UUID,
        type: MomentType,
        title: String,
        date: Date = .now,
        durationMinutes: Int,
        timeQuality: TimeQuality,
        notes: String? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.type = type
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.timeQuality = timeQuality
        self.notes = notes
    }
}
