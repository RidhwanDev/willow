import Foundation

public enum ReflectionMood: String, Codable, CaseIterable, Identifiable {
    case flourishing
    case steady
    case tired
    case needsCare

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .flourishing: "Flourishing"
        case .steady: "Steady"
        case .tired: "Tired"
        case .needsCare: "Need care"
        }
    }

    var symbolName: String {
        switch self {
        case .flourishing: "sun.max.fill"
        case .steady: "leaf.fill"
        case .tired: "cloud.sun.fill"
        case .needsCare: "hands.sparkles.fill"
        }
    }
}
