import Foundation
import SwiftData

@Model
final class WeeklyReflection {
    var id: UUID
    var weekStartDate: Date
    var parentId: UUID
    var mood: ReflectionMood
    var energyLevel: Int
    var note: String?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        parentId: UUID,
        mood: ReflectionMood,
        energyLevel: Int,
        note: String? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.parentId = parentId
        self.mood = mood
        self.energyLevel = min(max(energyLevel, 1), 5)
        self.note = note
    }
}
