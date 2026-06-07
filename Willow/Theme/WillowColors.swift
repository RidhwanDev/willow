import SwiftUI

enum WillowColors {
    static let cream = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let softCream = Color(red: 1.0, green: 0.98, blue: 0.93)
    static let leaf = Color(red: 0.43, green: 0.62, blue: 0.38)
    static let deepLeaf = Color(red: 0.20, green: 0.39, blue: 0.28)
    static let moss = Color(red: 0.62, green: 0.72, blue: 0.48)
    static let amber = Color(red: 0.93, green: 0.66, blue: 0.32)
    static let sky = Color(red: 0.70, green: 0.86, blue: 0.90)
    static let bark = Color(red: 0.48, green: 0.32, blue: 0.22)
    static let ink = Color(red: 0.16, green: 0.20, blue: 0.17)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.43)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [sky.opacity(0.68), cream, softCream],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
