import Foundation

struct WellbeingEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func parentState(for parent: ParentProfile, moments: [WellbeingMoment], referenceDate: Date = .now) -> ParentState {
        let recentMoments = momentsForParent(parent.id, in: moments, referenceDate: referenceDate)
        if hasGoneWithoutCare(parent.id, moments: moments, referenceDate: referenceDate) {
            return .needsCare
        }

        let score = recentMoments.reduce(0.0) { $0 + points(for: $1.timeQuality, parentFocused: true) }
        switch score {
        case 8...: return .flourishing
        case 5..<8: return .steady
        case 2..<5: return .tired
        default: return .needsCare
        }
    }

    func familyTreeState(for parents: [ParentProfile], moments: [WellbeingMoment], referenceDate: Date = .now) -> FamilyTreeState {
        let recentMoments = moments.filter { $0.date >= sevenDaysAgo(from: referenceDate) }
        let score = recentMoments.reduce(0.0) { $0 + points(for: $1.timeQuality, parentFocused: false) }

        switch score {
        case 12...: return .flourishing
        case 8..<12: return .growing
        case 5..<8: return .steady
        case 2..<5: return .tired
        default: return .needsCare
        }
    }

    func nudge(for parents: [ParentProfile], moments: [WellbeingMoment], referenceDate: Date = .now) -> String {
        for parent in parents.sorted(by: { $0.createdAt < $1.createdAt }) {
            if hasGoneWithoutCare(parent.id, moments: moments, referenceDate: referenceDate) {
                return "\(parent.name) may need protected time soon. Could you reserve a little space this week?"
            }
        }

        let coupleMoments = moments.filter { $0.timeQuality == .coupleTime && $0.date >= sevenDaysAgo(from: referenceDate) }
        if coupleMoments.isEmpty {
            return "A small protected moment together could help your willow feel more rooted."
        }

        return "You both shared a lovely moment this week. Keep protecting the little spaces that help you feel like yourselves."
    }

    func statusText(for state: FamilyTreeState) -> String {
        switch state {
        case .flourishing:
            return "Your family has had rich, restorative moments this week. The willow feels bright and alive."
        case .growing:
            return "Your family has had some good moments this week. A little protected time would help it thrive."
        case .steady:
            return "There is care here. A few intentional pockets of rest could help the willow grow stronger."
        case .tired:
            return "Your willow could use some care. A gentle plan for protected time may help soon."
        case .needsCare:
            return "Your willow is asking for care. Start with one small moment that gives someone real breathing room."
        }
    }

    func weeklySummary(moments: [WellbeingMoment], referenceDate: Date = .now) -> String {
        let recentMoments = moments.filter { $0.date >= sevenDaysAgo(from: referenceDate) }
        let rechargeCount = recentMoments.filter { $0.timeQuality == .protectedTime || $0.timeQuality == .personalTime }.count
        let protectedCount = recentMoments.filter { $0.timeQuality == .protectedTime }.count
        let coupleCount = recentMoments.filter { $0.timeQuality == .coupleTime }.count
        return "This week, your family shared \(rechargeCount) recharge moments, \(protectedCount) protected time block\(protectedCount == 1 ? "" : "s"), and \(coupleCount) couple moment\(coupleCount == 1 ? "" : "s")."
    }

    private func momentsForParent(_ parentId: UUID, in moments: [WellbeingMoment], referenceDate: Date) -> [WellbeingMoment] {
        moments.filter { $0.parentId == parentId && $0.date >= sevenDaysAgo(from: referenceDate) }
    }

    private func hasGoneWithoutCare(_ parentId: UUID, moments: [WellbeingMoment], referenceDate: Date) -> Bool {
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: referenceDate) ?? referenceDate
        return moments.filter { moment in
            moment.parentId == parentId &&
            moment.date >= fiveDaysAgo &&
            (moment.timeQuality == .protectedTime || moment.timeQuality == .personalTime)
        }.isEmpty
    }

    private func sevenDaysAgo(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: -7, to: date) ?? date
    }

    private func points(for quality: TimeQuality, parentFocused: Bool) -> Double {
        switch quality {
        case .protectedTime: return 3
        case .personalTime: return 2
        case .passiveTime: return 0.5
        case .sharedFamilyTime: return parentFocused ? 0 : 2
        case .coupleTime: return parentFocused ? 0 : 3
        }
    }
}
