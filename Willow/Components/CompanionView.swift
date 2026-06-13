import SwiftUI

struct CompanionView: View {
    let parent: ParentProfile
    let state: ParentState
    let delay: Double

    @State private var isBouncing = false
    @State private var isBlinking = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(bodyColor.gradient)
                    .frame(width: 54, height: 54)
                    .saturation(state == .needsCare ? 0.45 : 1)

                HStack(spacing: 10) {
                    eye
                    eye
                }
                .offset(y: -4)

                companionAccent
                    .offset(y: 24)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: symbolName)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(WillowColors.deepLeaf.opacity(0.82), in: Circle())
                    .offset(x: 5, y: -5)
            }
            .offset(y: isBouncing ? -5 : 3)
            .animation(.easeInOut(duration: bounceDuration).repeatForever(autoreverses: true).delay(delay), value: isBouncing)

        }
        .onAppear {
            isBouncing = state != .needsCare
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true).delay(2.4 + delay)) {
                isBlinking = true
            }
        }
    }

    private var eye: some View {
        Capsule()
            .fill(WillowColors.ink)
            .frame(width: 5, height: isBlinking ? 2 : 7)
    }

    private var companionAccent: some View {
        Capsule()
            .fill(.white.opacity(0.52))
            .frame(width: 26, height: 12)
    }

    private var symbolName: String {
        switch parent.companionType.lowercased() {
        case "fox": "pawprint.fill"
        case "rabbit": "hare.fill"
        case "squirrel": "leaf.fill"
        case "otter": "drop.fill"
        default: "sparkle"
        }
    }

    private var bodyColor: Color {
        switch parent.companionType.lowercased() {
        case "fox": WillowColors.amber
        case "rabbit": Color(red: 0.78, green: 0.69, blue: 0.60)
        case "squirrel": Color(red: 0.56, green: 0.42, blue: 0.30)
        case "otter": Color(red: 0.45, green: 0.55, blue: 0.58)
        default: WillowColors.moss
        }
    }

    private var bounceDuration: Double {
        switch state {
        case .flourishing: 1.15
        case .steady: 1.8
        case .tired: 2.4
        case .needsCare: 4.0
        }
    }
}
