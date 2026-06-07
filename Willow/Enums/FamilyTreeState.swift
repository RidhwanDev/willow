import Foundation

public enum FamilyTreeState: String, Codable {
    case flourishing
    case growing
    case steady
    case tired
    case needsCare

    var title: String {
        switch self {
        case .flourishing: "flourishing"
        case .growing: "growing"
        case .steady: "steady"
        case .tired: "a little tired"
        case .needsCare: "asking for care"
        }
    }
}
