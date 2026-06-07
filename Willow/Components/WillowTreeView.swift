import SwiftUI

struct WillowTreeView: View {
    let state: FamilyTreeState
    @State private var sway = false
    @State private var pulse = false
    @State private var drift = false

    var body: some View {
        ZStack {
            groundShadow
            atmosphere
            driftingLeaves
            trunkLayer
                .rotationEffect(.degrees(sway ? swayAmount : -swayAmount), anchor: .bottom)
            canopyLayer
                .offset(y: state == .needsCare ? 10 : 0)
                .rotationEffect(.degrees(sway ? -1.4 : 1.4), anchor: .bottom)
            frondLayer
                .offset(y: state == .needsCare ? 12 : 0)
        }
        .frame(height: 360)
        .saturation(state == .needsCare ? 0.62 : 1)
        .onAppear {
            sway = true
            pulse = true
            drift = true
        }
    }

    private var atmosphere: some View {
        ZStack {
            Circle()
                .fill(glowColor.opacity(pulse ? glowOpacity : glowOpacity * 0.45))
                .frame(width: 292, height: 292)
                .blur(radius: 34)
            Circle()
                .fill(WillowColors.amber.opacity(pulse ? 0.13 * vitality : 0.05 * vitality))
                .frame(width: 154, height: 154)
                .blur(radius: 18)
                .offset(x: -42, y: -40)
        }
        .animation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true), value: pulse)
    }

    private var groundShadow: some View {
        Ellipse()
            .fill(WillowColors.deepLeaf.opacity(0.16))
            .frame(width: 205, height: 28)
            .blur(radius: 8)
            .offset(y: 158)
    }

    private var trunkLayer: some View {
        ZStack(alignment: .bottom) {
            branch(direction: -1, reach: 104, lift: 118, width: 13, x: -6, y: -42)
            branch(direction: 1, reach: 112, lift: 112, width: 12, x: 7, y: -38)
            branch(direction: -0.45, reach: 66, lift: 134, width: 9, x: -2, y: -58)
            branch(direction: 0.48, reach: 62, lift: 132, width: 8, x: 4, y: -64)

            WillowTrunkShape()
                .fill(
                    LinearGradient(
                        colors: [WillowColors.bark.opacity(0.96), Color(red: 0.62, green: 0.43, blue: 0.29), WillowColors.bark.opacity(0.78)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .frame(width: 78, height: 208)
                .offset(y: 76)

            WillowTrunkShape()
                .stroke(Color.white.opacity(0.16), lineWidth: 2)
                .frame(width: 55, height: 185)
                .offset(x: -8, y: 67)
        }
        .shadow(color: WillowColors.bark.opacity(0.20), radius: 8, x: 0, y: 6)
        .animation(.easeInOut(duration: swayDuration).repeatForever(autoreverses: true), value: sway)
    }

    private func branch(direction: CGFloat, reach: CGFloat, lift: CGFloat, width: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        WillowBranchShape(direction: direction, reach: reach, lift: lift)
            .stroke(
                LinearGradient(colors: [WillowColors.bark.opacity(0.92), WillowColors.bark.opacity(0.48)], startPoint: .bottom, endPoint: .top),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
            .frame(width: reach + 42, height: lift + 24)
            .offset(x: x, y: y)
    }

    private var canopyLayer: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                canopyCluster(index: index)
            }
            ForEach(0..<22, id: \.self) { index in
                crownLeaf(index: index)
            }
        }
        .frame(width: 315, height: 255)
        .animation(.easeInOut(duration: swayDuration).repeatForever(autoreverses: true), value: sway)
    }

    private func canopyCluster(index: Int) -> some View {
        let size = clusterSize(index)
        let offset = clusterOffset(index)
        let color = canopyColor(index)

        return Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.96), color.opacity(0.50), color.opacity(0.08)],
                    center: .center,
                    startRadius: 8,
                    endRadius: size.width * 0.56
                )
            )
            .frame(width: size.width, height: size.height)
            .offset(x: offset.x + (sway ? clusterDrift(index) : -clusterDrift(index)), y: offset.y)
            .blur(radius: index.isMultiple(of: 4) ? 1.2 : 0.2)
            .opacity(clusterOpacity)
    }

    private func crownLeaf(index: Int) -> some View {
        let offset = crownLeafOffset(index)

        return LeafShape()
            .fill(leafGradient(index))
            .frame(width: CGFloat(17 + index % 5), height: CGFloat(34 + index % 7))
            .rotationEffect(.degrees(Double(index * 31) + (sway ? 5 : -5)))
            .offset(x: offset.x, y: offset.y)
            .opacity(0.58 + vitality * 0.30)
    }

    private var frondLayer: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { index in
                frond(index: index)
            }
        }
        .frame(width: 330, height: 305)
        .animation(.easeInOut(duration: swayDuration).repeatForever(autoreverses: true), value: sway)
    }

    private func frond(index: Int) -> some View {
        WillowFrondView(index: index, leafColor: frondColor(index), vitality: vitality)
            .frame(width: frondWidth(index), height: frondHeight(index))
            .rotationEffect(.degrees(frondRotation(index) + (sway ? frondSway(index) : -frondSway(index))), anchor: .top)
            .offset(x: frondX(index), y: frondY(index))
            .opacity(frondOpacity(index))
    }

    private var driftingLeaves: some View {
        ZStack {
            ForEach(0..<floatingLeafCount, id: \.self) { index in
                floatingLeaf(index: index)
            }
        }
    }

    private func floatingLeaf(index: Int) -> some View {
        LeafShape()
            .fill(WillowColors.amber.opacity(0.45 * vitality))
            .frame(width: 10, height: 22)
            .rotationEffect(.degrees(drift ? Double(index * 37 + 180) : Double(index * 19)))
            .offset(x: CGFloat((index % 6) * 48 - 120) + (drift ? 18 : -12), y: drift ? 140 : -144)
            .opacity(0.18 + vitality * 0.48)
            .animation(.linear(duration: Double(8 + index)).repeatForever(autoreverses: false).delay(Double(index) * 0.58), value: drift)
    }

    private func clusterSize(_ index: Int) -> CGSize {
        CGSize(width: CGFloat(82 + (index % 5) * 13), height: CGFloat(66 + (index % 4) * 12))
    }

    private func clusterOffset(_ index: Int) -> CGPoint {
        let row = index / 6
        let column = index % 6
        let x = CGFloat(column * 48 - 120 + (row == 1 ? 22 : 0))
        let y = CGFloat(row * 46 - 112 + abs(column - 2) * 7)
        return CGPoint(x: x, y: y)
    }

    private func clusterDrift(_ index: Int) -> CGFloat {
        CGFloat((index % 4) + 1) * 0.9
    }

    private func crownLeafOffset(_ index: Int) -> CGPoint {
        let column = index % 8
        let row = index / 8
        return CGPoint(x: CGFloat(column * 37 - 130 + (row * 9)), y: CGFloat(row * 48 - 105 + abs(column - 3) * 5))
    }

    private func leafGradient(_ index: Int) -> LinearGradient {
        LinearGradient(colors: [frondColor(index).opacity(0.95), WillowColors.moss.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func canopyColor(_ index: Int) -> Color {
        switch state {
        case .flourishing:
            return index.isMultiple(of: 3) ? Color(red: 0.52, green: 0.74, blue: 0.40) : WillowColors.leaf
        case .growing:
            return index.isMultiple(of: 2) ? WillowColors.leaf : WillowColors.moss
        case .steady:
            return index.isMultiple(of: 2) ? WillowColors.leaf.opacity(0.86) : WillowColors.moss.opacity(0.82)
        case .tired:
            return index.isMultiple(of: 2) ? WillowColors.moss.opacity(0.72) : Color(red: 0.54, green: 0.59, blue: 0.38)
        case .needsCare:
            return WillowColors.muted.opacity(0.68)
        }
    }

    private func frondColor(_ index: Int) -> Color {
        switch state {
        case .flourishing:
            return index.isMultiple(of: 2) ? Color(red: 0.57, green: 0.78, blue: 0.43) : WillowColors.leaf
        case .growing:
            return index.isMultiple(of: 2) ? WillowColors.leaf : WillowColors.moss
        case .steady:
            return WillowColors.leaf.opacity(0.84)
        case .tired:
            return WillowColors.moss.opacity(0.66)
        case .needsCare:
            return WillowColors.muted.opacity(0.60)
        }
    }

    private func frondWidth(_ index: Int) -> CGFloat { CGFloat(24 + (index % 3) * 5) }
    private func frondHeight(_ index: Int) -> CGFloat { CGFloat(112 + (index % 6) * 15) }
    private func frondRotation(_ index: Int) -> Double { Double((index % 9) * 5 - 20) }
    private func frondSway(_ index: Int) -> Double { Double((index % 5) + 2) * 0.55 }
    private func frondX(_ index: Int) -> CGFloat { CGFloat((index % 12) * 25 - 138) }
    private func frondY(_ index: Int) -> CGFloat { CGFloat((index / 12) * 16 - 72 + abs((index % 12) - 5) * 4) }

    private func frondOpacity(_ index: Int) -> Double {
        let edgeFade = abs((index % 12) - 5) > 4 ? 0.78 : 1.0
        return edgeFade * (0.58 + vitality * 0.38)
    }

    private var floatingLeafCount: Int {
        switch state {
        case .flourishing: 11
        case .growing: 8
        case .steady: 5
        case .tired: 3
        case .needsCare: 2
        }
    }

    private var vitality: Double {
        switch state {
        case .flourishing: 1.0
        case .growing: 0.86
        case .steady: 0.72
        case .tired: 0.48
        case .needsCare: 0.30
        }
    }

    private var clusterOpacity: Double { 0.64 + vitality * 0.30 }
    private var swayAmount: Double { state == .needsCare ? 0.7 : 1.7 }
    private var glowColor: Color { state == .flourishing ? WillowColors.amber : WillowColors.leaf }
    private var glowOpacity: Double { 0.12 + vitality * 0.24 }

    private var swayDuration: Double {
        switch state {
        case .flourishing: 2.9
        case .growing: 3.35
        case .steady: 3.9
        case .tired: 4.8
        case .needsCare: 5.8
        }
    }
}

struct WillowFrondView: View {
    let index: Int
    let leafColor: Color
    let vitality: Double

    var body: some View {
        ZStack(alignment: .top) {
            WillowFrondStemShape(curve: curve)
                .stroke(leafColor.opacity(0.62), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

            ForEach(0..<leafCount, id: \.self) { leafIndex in
                leaflet(leafIndex)
            }
        }
    }

    private func leaflet(_ leafIndex: Int) -> some View {
        let side: CGFloat = leafIndex.isMultiple(of: 2) ? -1 : 1
        let y = CGFloat(leafIndex + 1) / CGFloat(leafCount + 1)
        let width = CGFloat(8 + (leafIndex % 3) * 2)
        let height = CGFloat(17 + (leafIndex % 4) * 2)
        let horizontal = side * CGFloat(5 + (leafIndex % 4) * 2) + curve * 18 * y

        return LeafShape()
            .fill(LinearGradient(colors: [leafColor.opacity(0.96), leafColor.opacity(0.58)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(Double(side * 28) + Double(curve * 20)))
            .offset(x: horizontal, y: y * 132)
            .opacity(0.50 + vitality * 0.45)
    }

    private var leafCount: Int { max(5, Int(6 + vitality * 5)) }
    private var curve: CGFloat { CGFloat((index % 7) - 3) * 0.055 }
}

struct WillowTrunkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.28, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.minY), control1: CGPoint(x: rect.midX - rect.width * 0.30, y: rect.height * 0.62), control2: CGPoint(x: rect.midX - rect.width * 0.20, y: rect.height * 0.24))
        path.addCurve(to: CGPoint(x: rect.midX + rect.width * 0.20, y: rect.maxY), control1: CGPoint(x: rect.midX + rect.width * 0.20, y: rect.height * 0.28), control2: CGPoint(x: rect.midX + rect.width * 0.32, y: rect.height * 0.68))
        path.closeSubpath()
        return path
    }
}

struct WillowBranchShape: Shape {
    let direction: CGFloat
    let reach: CGFloat
    let lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.midX, y: rect.maxY)
        let end = CGPoint(x: rect.midX + direction * reach * 0.45, y: rect.maxY - lift)
        let control1 = CGPoint(x: rect.midX + direction * reach * 0.10, y: rect.maxY - lift * 0.34)
        let control2 = CGPoint(x: rect.midX + direction * reach * 0.36, y: rect.maxY - lift * 0.72)
        path.move(to: start)
        path.addCurve(to: end, control1: control1, control2: control2)
        return path
    }
}

struct WillowFrondStemShape: Shape {
    let curve: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX + curve * rect.width * 1.8, y: rect.maxY),
            control1: CGPoint(x: rect.midX + curve * rect.width, y: rect.height * 0.32),
            control2: CGPoint(x: rect.midX - curve * rect.width * 0.8, y: rect.height * 0.68)
        )
        return path
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: rect.height * 0.20), control2: CGPoint(x: rect.maxX * 0.92, y: rect.height * 0.78))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.height * 0.78), control2: CGPoint(x: rect.minX, y: rect.height * 0.20))
        return path
    }
}
