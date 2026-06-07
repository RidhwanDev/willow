import Foundation

public enum ParentState: String, Codable {
    case flourishing
    case steady
    case tired
    case needsCare

    var title: String {
        switch self {
        case .flourishing: "Flourishing"
        case .steady: "Steady"
        case .tired: "Tired"
        case .needsCare: "Needs care"
        }
    }
}
