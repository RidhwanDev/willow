import Foundation

public enum TimeQuality: String, Codable, CaseIterable, Identifiable {
    case protectedTime
    case personalTime
    case passiveTime
    case sharedFamilyTime
    case coupleTime

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .protectedTime: "Protected"
        case .personalTime: "Personal"
        case .passiveTime: "Passive"
        case .sharedFamilyTime: "Family"
        case .coupleTime: "Couple"
        }
    }

    var explanation: String {
        switch self {
        case .protectedTime: "Someone else was fully responsible."
        case .personalTime: "You had time for yourself, but were still lightly on duty."
        case .passiveTime: "You had downtime, but it wasn't really restorative."
        case .sharedFamilyTime: "You spent meaningful time together."
        case .coupleTime: "You protected time for your relationship."
        }
    }
}
