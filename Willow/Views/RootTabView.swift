import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "tree.fill") }

            MomentsView()
                .tabItem { Label("Moments", systemImage: "sparkles") }

            ProtectView()
                .tabItem { Label("Protect", systemImage: "shield.lefthalf.filled") }

            ReflectionView()
                .tabItem { Label("Reflection", systemImage: "leaf.arrow.circlepath") }
        }
        .tint(WillowColors.deepLeaf)
    }
}
