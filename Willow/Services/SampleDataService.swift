import Foundation
import SwiftData

struct SampleDataService {
    static let ridhwanId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let anabId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    @MainActor
    static func seedIfNeeded(modelContext: ModelContext, parents: [ParentProfile]) {
        guard parents.isEmpty else { return }

        let ridhwan = ParentProfile(id: ridhwanId, name: "Ridhwan", companionName: "Fenn", companionType: "Fox")
        let anab = ParentProfile(id: anabId, name: "Anab", companionName: "Luma", companionType: "Rabbit")
        modelContext.insert(ridhwan)
        modelContext.insert(anab)

        let moments: [WellbeingMoment] = [
            WellbeingMoment(parentId: ridhwan.id, type: .exercise, title: "Gym", date: daysAgo(1), durationMinutes: 60, timeQuality: .protectedTime),
            WellbeingMoment(parentId: anab.id, type: .friends, title: "Coffee with friends", date: daysAgo(2), durationMinutes: 90, timeQuality: .protectedTime),
            WellbeingMoment(parentId: ridhwan.id, type: .sideProject, title: "Built AkhiNet", date: daysAgo(3), durationMinutes: 120, timeQuality: .personalTime),
            WellbeingMoment(parentId: anab.id, type: .familyTime, title: "Family walk", date: daysAgo(4), durationMinutes: 60, timeQuality: .sharedFamilyTime),
            WellbeingMoment(parentId: anab.id, type: .coupleTime, title: "Date night", date: daysAgo(5), durationMinutes: 120, timeQuality: .coupleTime)
        ]

        moments.forEach(modelContext.insert)

        let plan = ProtectedTimePlan(
            parentId: ridhwan.id,
            protectedByParentId: anab.id,
            title: "Build AkhiNet",
            startDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now) ?? .now
        )
        modelContext.insert(plan)
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
