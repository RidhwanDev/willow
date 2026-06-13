import SwiftUI

// MARK: - The willow tree

/// The heart of the app, matching the watercolor design sheet:
/// a stout trunk with organic root toes, a broad canopy built from crisp
/// scalloped leaf masses (no blurry gradient bubbles), long hanging fronds
/// that cascade like curtains, and grass tufts hugging the base.
///
/// Motion design:
/// - One `TimelineView` clock drives everything; no `repeatForever`
///   animations anywhere, so motion can never restart or jump.
/// - Wind is a travelling wave: fronds, canopy masses and base grass all
///   sample the same wave at their own x position, so gusts roll across
///   the tree. A slow gust envelope makes the wind breathe.
/// - Fronds bend like hanging cloth (quadratic curves whose tips swing
///   further than their roots); leaflets align to the local curve tangent.
/// - The frond curtain and drifting leaves render in a single `Canvas`,
///   so ~150 animated leaflets cost one view.
struct WillowTreeView: View {
    let state: FamilyTreeState
    var season: WillowSeason = .current()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 40, paused: reduceMotion)) { context in
            WillowTreeFigure(
                pose: WillowTreePose(
                    time: context.date.timeIntervalSinceReferenceDate,
                    state: state,
                    season: season
                )
            )
        }
        .frame(width: 340, height: 360)
    }
}

// MARK: - Pose (wind + wellbeing rig)

struct WillowTreePose {
    let time: TimeInterval
    let state: FamilyTreeState
    let season: WillowSeason

    var vitality: Double {
        switch state {
        case .flourishing: 1.0
        case .growing: 0.86
        case .steady: 0.72
        case .tired: 0.50
        case .needsCare: 0.32
        }
    }

    /// Slow envelope so the wind rises and falls instead of ticking.
    var gust: Double { 0.7 + 0.3 * sin(time * 2 * .pi * 0.03) }

    /// Gentle whole-canopy breathing.
    var breath: Double { sin(time * 2 * .pi / 5.2) }

    /// Travelling wind wave sampled at horizontal position `x`, so gusts
    /// roll across the tree from one side to the other.
    func sway(x: CGFloat, amplitude: Double, phase: Double = 0) -> Double {
        gust * amplitude * sin(time * 2 * .pi * 0.14 - Double(x) / 64 + phase)
    }

    /// High-frequency micro-motion for individual leaflets.
    func flutter(_ seed: Double) -> Double {
        sin(time * 2 * .pi * 0.9 + seed)
    }

    /// Tired/neglected trees sag a little.
    var droop: CGFloat {
        switch state {
        case .needsCare: 10
        case .tired: 4
        default: 0
        }
    }

    // MARK: Colors (design sheet palette)

    private static let canopyTones: [Color] = [
        Color(red: 0.43, green: 0.58, blue: 0.41),   // deep shade
        Color(red: 0.50, green: 0.65, blue: 0.48),   // #7FA57A
        Color(red: 0.66, green: 0.77, blue: 0.60),   // #A9C59A
        Color(red: 0.86, green: 0.92, blue: 0.81)    // #DCEACF highlight
    ]

    func canopyColor(_ tone: Int) -> Color {
        var color = Self.canopyTones[min(max(tone, 0), 3)]
        let tint = season.canopyTint
        if tint.amount > 0 {
            color = color.mix(with: tint.color, by: tint.amount)
        }
        return color.mix(
            with: Color(red: 0.55, green: 0.58, blue: 0.52),
            by: (1 - vitality) * 0.45
        )
    }

    var stemColor: Color { canopyColor(0).mix(with: .black, by: 0.18) }

    var leafTones: [Color] { [canopyColor(1), canopyColor(2), canopyColor(3)] }

    var driftLeafColor: Color {
        let amber = Color(red: 0.93, green: 0.66, blue: 0.32)
        let tint = season.canopyTint
        guard tint.amount > 0 else { return amber }
        return amber.mix(with: tint.color, by: tint.amount * 0.7)
    }
}

// MARK: - Figure

private struct WillowTreeFigure: View {
    let pose: WillowTreePose

    // Layout is absolute in a 340x360 canvas; ground line sits at y 352.

    var body: some View {
        ZStack {
            contactShadow
            trunk
            canopy
            frondCanvas
            baseGrass
        }
        .frame(width: 340, height: 360)
        .saturation(pose.state == .needsCare ? 0.65 : 1)
        .animation(.spring(response: 0.8, dampingFraction: 0.85), value: pose.state)
    }

    private var contactShadow: some View {
        Ellipse()
            .fill(WillowColors.deepLeaf.opacity(0.15))
            .frame(width: 200, height: 24)
            .blur(radius: 8)
            .position(x: 170, y: 348)
    }

    // MARK: Trunk

    private var trunk: some View {
        WillowTrunkShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.68, green: 0.52, blue: 0.38),
                        Color(red: 0.55, green: 0.42, blue: 0.31),
                        Color(red: 0.40, green: 0.29, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                WillowBarkDetailShape()
                    .stroke(
                        Color(red: 0.33, green: 0.23, blue: 0.15).opacity(0.30),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                    )
            }
            .overlay {
                Ellipse()
                    .fill(Color(red: 0.33, green: 0.23, blue: 0.15).opacity(0.28))
                    .frame(width: 9, height: 14)
                    .offset(x: -10, y: 26)
            }
            .frame(width: 130, height: 205)
            .position(x: 170, y: 250)
    }

    // MARK: Canopy (layered scalloped masses, deep to light)

    private static let blobs: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, tone: Int, seed: Double)] = [
        (170, 122, 290, 180, 0, 1.0),                                  // base mass
        (78, 150, 150, 112, 0, 2.4), (262, 150, 150, 112, 0, 4.1),    // low side lobes
        (120, 104, 185, 125, 1, 3.2), (224, 110, 172, 118, 1, 5.0),   // mid layer
        (170, 82, 165, 110, 1, 0.6),
        (138, 70, 125, 84, 2, 2.0), (216, 84, 108, 74, 2, 4.6),       // light layer
        (158, 52, 76, 50, 3, 1.4), (212, 60, 58, 40, 3, 3.7)          // pale glints
    ]

    private var canopy: some View {
        ZStack {
            ForEach(0..<Self.blobs.count, id: \.self) { index in
                let blob = Self.blobs[index]
                let drift = CGFloat(pose.sway(x: blob.x, amplitude: 3, phase: Double(index) * 0.2))
                WillowCanopyBlobShape(seed: blob.seed)
                    .fill(blobFill(blob.tone))
                    .frame(width: blob.w, height: blob.h)
                    .position(x: blob.x + drift, y: blob.y + pose.droop)
            }
        }
        .scaleEffect(1 + 0.007 * pose.breath, anchor: UnitPoint(x: 0.5, y: 0.55))
        .frame(width: 340, height: 360)
    }

    private func blobFill(_ tone: Int) -> LinearGradient {
        let color = pose.canopyColor(tone)
        return LinearGradient(
            colors: [
                color.mix(with: .white, by: 0.10),
                color,
                color.mix(with: .black, by: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Base grass (covers the root joint, follows the seasons)

    private var baseGrass: some View {
        ZStack {
            WillowGrassTuft(season: pose.season, width: 30)
                .rotationEffect(.degrees(pose.sway(x: 132, amplitude: 1.4)), anchor: .bottom)
                .position(x: 132, y: 344)
            WillowGrassTuft(season: pose.season, width: 38)
                .rotationEffect(.degrees(pose.sway(x: 172, amplitude: 1.6)), anchor: .bottom)
                .position(x: 172, y: 342)
            WillowGrassTuft(season: pose.season, width: 26)
                .rotationEffect(.degrees(pose.sway(x: 214, amplitude: 1.3)), anchor: .bottom)
                .position(x: 214, y: 345)
            WillowGrassTuft(season: pose.season, width: 20)
                .rotationEffect(.degrees(pose.sway(x: 150, amplitude: 1.2)), anchor: .bottom)
                .position(x: 150, y: 347)
        }
    }

    // MARK: Hanging fronds + drifting leaves (single Canvas)

    private struct Frond {
        let x: CGFloat
        let y: CGFloat
        let length: CGFloat
        let stemWidth: CGFloat
        let leafScale: CGFloat
    }

    /// Crown fronds (short, draped over the top of the canopy) followed by
    /// the main curtain. Built once: a dense comb with deterministic jitter
    /// and a bell-shaped length profile so the middle hangs lowest, like a
    /// real weeping willow. Drawn crown-first so the long curtain layers
    /// over it.
    private static let fronds: [Frond] = {
        var result: [Frond] = []

        // Short fronds spilling over the crown for depth on top of the canopy.
        let crown: [(x: CGFloat, y: CGFloat, length: CGFloat)] = [
            (118, 84, 56), (148, 70, 66), (178, 66, 72), (208, 74, 64),
            (236, 90, 52), (100, 102, 48), (258, 106, 46), (192, 92, 60),
            (134, 78, 60), (224, 80, 58)
        ]
        for frond in crown {
            result.append(Frond(x: frond.x, y: frond.y, length: frond.length, stemWidth: 1.0, leafScale: 0.82))
        }

        // Main curtain: a dense row of strands across the canopy underside.
        let count = 30
        for i in 0..<count {
            let f = Double(i) / Double(count - 1)          // 0...1 across the width
            let bell = sin(f * .pi)                         // 0 at edges, 1 in the middle
            let jitterX = CGFloat(sin(Double(i) * 12.9898)) * 4
            let jitterLen = CGFloat(sin(Double(i) * 4.231)) * 12
            let x = 22 + CGFloat(f) * 296 + jitterX
            let y = 148 + CGFloat(bell) * 48
            let length = 86 + CGFloat(bell) * 66 + jitterLen
            result.append(Frond(x: x, y: y, length: length, stemWidth: 1.2, leafScale: 1.0))
        }
        return result
    }()

    private static let drifters: [(x: CGFloat, speed: Double, seed: Double)] = [
        (70, 0.060, 0.10), (130, 0.050, 0.45), (200, 0.070, 0.80),
        (250, 0.055, 0.25), (160, 0.045, 0.60), (290, 0.065, 0.90)
    ]

    private var frondCanvas: some View {
        Canvas { context, _ in
            let tones = pose.leafTones
            let leafAlpha = 0.55 + 0.35 * pose.vitality
            let stemColor = pose.stemColor.opacity(0.70)

            for (index, frond) in Self.fronds.enumerated() {
                let amplitude = 6 + Double(frond.length) * 0.07
                let sway = CGFloat(pose.sway(x: frond.x, amplitude: amplitude, phase: Double(index) * 0.35))
                let anchor = CGPoint(x: frond.x, y: frond.y + pose.droop)
                let tip = CGPoint(x: frond.x + sway, y: frond.y + frond.length + pose.droop)
                let control = CGPoint(x: frond.x + sway * 0.42, y: frond.y + frond.length * 0.55 + pose.droop)

                var stem = Path()
                stem.move(to: anchor)
                stem.addQuadCurve(to: tip, control: control)
                context.stroke(stem, with: .color(stemColor), style: StrokeStyle(lineWidth: frond.stemWidth, lineCap: .round))

                let leafCount = max(5, Int(frond.length / 18))
                let scale = frond.leafScale
                for leaf in 0..<leafCount {
                    let t = CGFloat(leaf + 1) / CGFloat(leafCount + 1)
                    let point = quadPoint(anchor, control, tip, t)
                    let tangent = quadTangent(anchor, control, tip, t)
                    let side: Double = leaf.isMultiple(of: 2) ? 1 : -1
                    let flutter = pose.flutter(Double(index) * 1.7 + Double(leaf) * 0.9) * 0.10
                    let rotation = Double(tangent) - .pi / 2 + side * 0.58 + flutter
                    let tone = tones[(index + leaf) % tones.count]

                    var leafPath = Path(ellipseIn: CGRect(x: -1.7 * scale, y: -5 * scale, width: 3.4 * scale, height: 10 * scale))
                    leafPath = leafPath.applying(
                        CGAffineTransform(rotationAngle: rotation)
                            .concatenating(CGAffineTransform(translationX: point.x, y: point.y))
                    )
                    context.fill(leafPath, with: .color(tone.opacity(leafAlpha)))
                }
            }

            // Drifting leaves: fade in and out over the loop so they never snap.
            for drifter in Self.drifters {
                let loopT = (pose.time * drifter.speed + drifter.seed).truncatingRemainder(dividingBy: 1)
                let y = 150 + CGFloat(loopT) * 200
                let x = drifter.x + CGFloat(sin(pose.time * 0.5 + drifter.seed * 10) * 26) + CGFloat(loopT) * 24
                let alpha = sin(.pi * loopT) * 0.75 * pose.vitality
                let rotation = pose.time * 1.1 + drifter.seed * 6

                var leafPath = Path(ellipseIn: CGRect(x: -2, y: -6, width: 4, height: 12))
                leafPath = leafPath.applying(
                    CGAffineTransform(rotationAngle: rotation)
                        .concatenating(CGAffineTransform(translationX: x, y: y))
                )
                context.fill(leafPath, with: .color(pose.driftLeafColor.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }

    private func quadPoint(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * a.x + 2 * mt * t * c.x + t * t * b.x,
            y: mt * mt * a.y + 2 * mt * t * c.y + t * t * b.y
        )
    }

    private func quadTangent(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGFloat {
        let mt = 1 - t
        let dx = 2 * mt * (c.x - a.x) + 2 * t * (b.x - c.x)
        let dy = 2 * mt * (c.y - a.y) + 2 * t * (b.y - c.y)
        return atan2(dy, dx)
    }
}

// MARK: - Shapes

/// Irregular scalloped leaf-mass outline. The wobble is deterministic per
/// seed and the geometry is static, so paths are never rebuilt per frame.
private struct WillowCanopyBlobShape: Shape {
    let seed: Double

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2
        let count = 22

        var points: [CGPoint] = []
        for i in 0..<count {
            let angle = Double(i) / Double(count) * 2 * .pi
            let wobble = 1
                + 0.07 * sin(3 * angle + seed)
                + 0.05 * sin(5 * angle + seed * 2)
                + 0.03 * sin(8 * angle + seed * 3)
            points.append(CGPoint(
                x: cx + CGFloat(cos(angle) * wobble) * rx,
                y: cy + CGFloat(sin(angle) * wobble) * ry
            ))
        }

        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        }

        var p = Path()
        p.move(to: mid(points[count - 1], points[0]))
        for i in 0..<count {
            let next = points[(i + 1) % count]
            p.addQuadCurve(to: mid(points[i], next), control: points[i])
        }
        p.closeSubpath()
        return p
    }
}

/// Stout trunk with organic root toes (no straight trapezoid flares) and a
/// three-finger fork that disappears up into the canopy.
private struct WillowTrunkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.03, y: h))
        // Left root: concave rise, knuckle dip, then into the shaft.
        p.addQuadCurve(to: CGPoint(x: w * 0.20, y: h * 0.92), control: CGPoint(x: w * 0.08, y: h * 0.97))
        p.addQuadCurve(to: CGPoint(x: w * 0.27, y: h * 0.97), control: CGPoint(x: w * 0.25, y: h * 0.93))
        p.addQuadCurve(to: CGPoint(x: w * 0.36, y: h * 0.80), control: CGPoint(x: w * 0.33, y: h * 0.92))
        p.addCurve(
            to: CGPoint(x: w * 0.40, y: h * 0.30),
            control1: CGPoint(x: w * 0.39, y: h * 0.62),
            control2: CGPoint(x: w * 0.38, y: h * 0.45)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.30, y: h * 0.06),
            control1: CGPoint(x: w * 0.38, y: h * 0.20),
            control2: CGPoint(x: w * 0.33, y: h * 0.10)
        )
        p.addQuadCurve(to: CGPoint(x: w * 0.46, y: h * 0.16), control: CGPoint(x: w * 0.40, y: h * 0.06))
        p.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.02), control: CGPoint(x: w * 0.50, y: h * 0.06))
        p.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.18), control: CGPoint(x: w * 0.62, y: h * 0.06))
        p.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.08), control: CGPoint(x: w * 0.66, y: h * 0.08))
        p.addCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.42),
            control1: CGPoint(x: w * 0.72, y: h * 0.18),
            control2: CGPoint(x: w * 0.66, y: h * 0.30)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.66, y: h * 0.80),
            control1: CGPoint(x: w * 0.62, y: h * 0.60),
            control2: CGPoint(x: w * 0.63, y: h * 0.72)
        )
        // Right root: knuckle dip mirroring the left.
        p.addQuadCurve(to: CGPoint(x: w * 0.75, y: h * 0.97), control: CGPoint(x: w * 0.69, y: h * 0.92))
        p.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.92), control: CGPoint(x: w * 0.77, y: h * 0.93))
        p.addQuadCurve(to: CGPoint(x: w * 0.98, y: h), control: CGPoint(x: w * 0.92, y: h * 0.97))
        p.closeSubpath()
        return p
    }
}

/// A few wavy grain lines for the watercolor bark texture.
private struct WillowBarkDetailShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.42, y: h * 0.85))
        p.addQuadCurve(to: CGPoint(x: w * 0.46, y: h * 0.45), control: CGPoint(x: w * 0.40, y: h * 0.65))
        p.move(to: CGPoint(x: w * 0.55, y: h * 0.90))
        p.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.50), control: CGPoint(x: w * 0.59, y: h * 0.70))
        p.move(to: CGPoint(x: w * 0.34, y: h * 0.80))
        p.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.60), control: CGPoint(x: w * 0.33, y: h * 0.70))
        return p
    }
}

#Preview("Willow tree states") {
    HStack(spacing: -60) {
        WillowTreeView(state: .flourishing)
        WillowTreeView(state: .needsCare)
    }
    .padding(20)
    .background(Color(red: 0.98, green: 0.95, blue: 0.88))
}
