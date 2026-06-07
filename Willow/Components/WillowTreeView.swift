import SwiftUI

struct WillowTreeView: View {
    let state: FamilyTreeState
    @State private var sway = false
    @State private var pulse = false
    @State private var drift = false

    var body: some View {
        ZStack {
            glow

            ForEach(0..<leafCount, id: \.self) { index in
                driftingLeaf(index: index)
            }

            trunk
                .rotationEffect(.degrees(sway ? swayAmount : -swayAmount), anchor: .bottom)
                .animation(.easeInOut(duration: swayDuration).repeatForever(autoreverses: true), value: sway)

            canopy
                .offset(y: state == .needsCare ? 12 : 0)
                .rotationEffect(.degrees(sway ? -2 : 2), anchor: .bottom)
                .animation(.easeInOut(duration: swayDuration).repeatForever(autoreverses: true), value: sway)
        }
        .frame(height: 330)
        .onAppear {
            sway = true
            pulse = true
            drift = true
        }
    }

    private var glow: some View {
        Circle()
            .fill(glowColor.opacity(pulse ? glowOpacity : glowOpacity * 0.55))
            .frame(width: 250, height: 250)
            .blur(radius: 28)
            .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)
    }

    private var trunk: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(LinearGradient(colors: [WillowColors.bark, WillowColors.bark.opacity(0.78)], startPoint: .bottom, endPoint: .top))
                .frame(width: 34, height: 178)
                .offset(y: 58)

            branch(angle: -35, width: 12, height: 96, x: -35, y: -3)
            branch(angle: 32, width: 11, height: 90, x: 34, y: 2)
            branch(angle: -16, width: 9, height: 78, x: -13, y: -34)
            branch(angle: 18, width: 8, height: 72, x: 16, y: -42)
        }
    }

    private func branch(angle: Double, width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(WillowColors.bark.opacity(0.82))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .offset(x: x, y: y)
    }

    private var canopy: some View {
        ZStack {
            ForEach(0..<28, id: \.self) { index in
                LeafShape()
                    .fill(leafGradient(for: index))
                    .frame(width: leafSize(index).width, height: leafSize(index).height)
                    .rotationEffect(.degrees(Double(index * 23) + (sway ? 5 : -5)))
                    .offset(x: leafOffset(index).x, y: leafOffset(index).y)
                    .opacity(leafOpacity)
            }
        }
        .frame(width: 270, height: 250)
        .saturation(state == .needsCare ? 0.55 : 1)
    }

    private func driftingLeaf(index: Int) -> some View {
        LeafShape()
            .fill(WillowColors.amber.opacity(0.55))
            .frame(width: 12, height: 22)
            .rotationEffect(.degrees(drift ? Double(index * 30 + 160) : Double(index * 19)))
            .offset(x: CGFloat((index % 5) * 48 - 96), y: drift ? 132 : -128)
            .opacity(state == .flourishing || state == .growing ? 0.75 : 0.28)
            .animation(.linear(duration: Double(7 + index)).repeatForever(autoreverses: false).delay(Double(index) * 0.55), value: drift)
    }

    private func leafGradient(for index: Int) -> LinearGradient {
        LinearGradient(
            colors: [leafColor.opacity(0.94), WillowColors.moss.opacity(index.isMultiple(of: 3) ? 0.86 : 0.66)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func leafOffset(_ index: Int) -> CGPoint {
        let row = index / 7
        let column = index % 7
        return CGPoint(x: CGFloat(column * 35 - 105 + (row.isMultiple(of: 2) ? 8 : -8)), y: CGFloat(row * 42 - 112 + abs(column - 3) * 7))
    }

    private func leafSize(_ index: Int) -> CGSize {
        CGSize(width: CGFloat(34 + (index % 4) * 4), height: CGFloat(64 + (index % 3) * 8))
    }

    private var leafCount: Int {
        switch state {
        case .flourishing: 9
        case .growing: 7
        case .steady: 5
        case .tired: 3
        case .needsCare: 2
        }
    }

    private var leafColor: Color {
        switch state {
        case .flourishing: WillowColors.leaf
        case .growing: WillowColors.moss
        case .steady: WillowColors.leaf.opacity(0.82)
        case .tired: WillowColors.moss.opacity(0.68)
        case .needsCare: WillowColors.muted.opacity(0.58)
        }
    }

    private var glowColor: Color {
        switch state {
        case .flourishing: WillowColors.amber
        case .growing: WillowColors.leaf
        case .steady: WillowColors.sky
        case .tired: WillowColors.moss
        case .needsCare: WillowColors.muted
        }
    }

    private var glowOpacity: Double {
        switch state {
        case .flourishing: 0.36
        case .growing: 0.28
        case .steady: 0.22
        case .tired: 0.16
        case .needsCare: 0.12
        }
    }

    private var leafOpacity: Double {
        state == .needsCare ? 0.72 : 0.96
    }

    private var swayAmount: Double {
        state == .needsCare ? 0.8 : 2.4
    }

    private var swayDuration: Double {
        switch state {
        case .flourishing: 2.8
        case .growing: 3.2
        case .steady: 3.8
        case .tired: 4.8
        case .needsCare: 5.5
        }
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY))
        return path
    }
}
