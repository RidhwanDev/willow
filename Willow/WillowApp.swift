import SwiftData
import SwiftUI

@main
struct WillowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            ParentProfile.self,
            WellbeingMoment.self,
            ProtectedTimePlan.self,
            WeeklyReflection.self
        ])
    }
}
