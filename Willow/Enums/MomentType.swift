import Foundation

public enum MomentType: String, Codable, CaseIterable, Identifiable {
    case exercise
    case friends
    case hobby
    case rest
    case learning
    case faithReflection
    case sideProject
    case coupleTime
    case familyTime
    case other

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .exercise: "Exercise"
        case .friends: "Friends"
        case .hobby: "Hobby"
        case .rest: "Rest"
        case .learning: "Learning"
        case .faithReflection: "Faith"
        case .sideProject: "Side project"
        case .coupleTime: "Couple time"
        case .familyTime: "Family time"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .exercise: "figure.run"
        case .friends: "cup.and.saucer.fill"
        case .hobby: "paintpalette.fill"
        case .rest: "moon.stars.fill"
        case .learning: "book.fill"
        case .faithReflection: "sparkles"
        case .sideProject: "hammer.fill"
        case .coupleTime: "heart.fill"
        case .familyTime: "figure.2.and.child.holdinghands"
        case .other: "leaf.fill"
        }
    }
}
