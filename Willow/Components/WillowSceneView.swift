import SwiftUI

// MARK: - Day phase

enum WillowDayPhase: String, CaseIterable {
    case day
    case night

    /// Smart default: follows the real clock.
    static func current(date: Date = .now) -> WillowDayPhase {
        let hour = Calendar.current.component(.hour, from: date)
        return (6..<19).contains(hour) ? .day : .night
    }

    var toggled: WillowDayPhase { self == .day ? .night : .day }
}

// MARK: - Season

enum WillowSeason: String, CaseIterable {
    case spring
    case summer
    case autumn
    case winter

    /// Smart default: follows the real calendar.
    static func current(date: Date = .now) -> WillowSeason {
        switch Calendar.current.component(.month, from: date) {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .autumn
        default: .winter
        }
    }

    var next: WillowSeason {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }

    var title: String { rawValue.capitalized }

    var symbolName: String {
        switch self {
        case .spring: "camera.macro"
        case .summer: "sun.max.fill"
        case .autumn: "wind"
        case .winter: "snowflake"
        }
    }

    func skyColors(for phase: WillowDayPhase) -> [Color] {
        switch (self, phase) {
        case (.spring, .day):
            [Color(red: 0.81, green: 0.91, blue: 0.95), Color(red: 0.93, green: 0.96, blue: 0.88)]
        case (.summer, .day):
            [Color(red: 0.75, green: 0.89, blue: 0.93), Color(red: 0.96, green: 0.94, blue: 0.84)]
        case (.autumn, .day):
            [Color(red: 0.95, green: 0.87, blue: 0.75), Color(red: 0.97, green: 0.92, blue: 0.84)]
        case (.winter, .day):
            [Color(red: 0.85, green: 0.89, blue: 0.91), Color(red: 0.95, green: 0.96, blue: 0.96)]
        case (.spring, .night):
            [Color(red: 0.19, green: 0.24, blue: 0.35), Color(red: 0.33, green: 0.39, blue: 0.50)]
        case (.summer, .night):
            [Color(red: 0.17, green: 0.21, blue: 0.32), Color(red: 0.30, green: 0.35, blue: 0.45)]
        case (.autumn, .night):
            [Color(red: 0.20, green: 0.18, blue: 0.28), Color(red: 0.36, green: 0.33, blue: 0.44)]
        case (.winter, .night):
            [Color(red: 0.16, green: 0.20, blue: 0.26), Color(red: 0.30, green: 0.36, blue: 0.42)]
        }
    }

    var groundLight: Color {
        switch self {
        case .spring: Color(red: 0.69, green: 0.82, blue: 0.56)
        case .summer: Color(red: 0.56, green: 0.75, blue: 0.44)
        case .autumn: Color(red: 0.76, green: 0.64, blue: 0.41)
        case .winter: Color(red: 0.94, green: 0.95, blue: 0.95)
        }
    }

    var groundShade: Color {
        switch self {
        case .spring: Color(red: 0.56, green: 0.71, blue: 0.45)
        case .summer: Color(red: 0.44, green: 0.64, blue: 0.33)
        case .autumn: Color(red: 0.64, green: 0.53, blue: 0.31)
        case .winter: Color(red: 0.80, green: 0.85, blue: 0.87)
        }
    }

    /// Blended into the willow's canopy colors so foliage follows the season.
    var canopyTint: (color: Color, amount: Double) {
        switch self {
        case .spring: (Color(red: 0.77, green: 0.86, blue: 0.62), 0.32)
        case .summer: (.clear, 0)
        case .autumn: (Color(red: 0.85, green: 0.63, blue: 0.28), 0.62)
        case .winter: (Color(red: 0.81, green: 0.85, blue: 0.81), 0.70)
        }
    }
}

// MARK: - Scene

/// A living diorama around the willow: season-aware sky, sun or moon and
/// stars, drifting clouds, a rolling seasonal ground and ambient particles
/// (blossom petals, fireflies, falling leaves, snow).
///
/// Performance follows the companion characters' approach: two small
/// `TimelineView` layers (sky effects behind the content, particles in
/// front) compute everything deterministically from time at a capped frame
/// rate, while the wrapped content is never re-evaluated per frame.
struct WillowSceneView<Content: View>: View {
    let season: WillowSeason
    let phase: WillowDayPhase
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: season.skyColors(for: phase),
                    startPoint: .top,
                    endPoint: .bottom
                )

                TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                    WillowCelestialLayer(
                        season: season,
                        phase: phase,
                        time: context.date.timeIntervalSinceReferenceDate,
                        size: size
                    )
                }

                Group {
                    WillowGroundView(season: season, width: size.width)
                    content()
                        .padding(.bottom, 14)
                    WillowForegroundView(season: season, width: size.width)
                        .allowsHitTesting(false)
                }
                .brightness(phase == .night ? -0.05 : 0)
                .saturation(phase == .night ? 0.85 : 1)

                TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                    WillowParticleLayer(
                        season: season,
                        phase: phase,
                        time: context.date.timeIntervalSinceReferenceDate,
                        size: size
                    )
                }
                .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
        }
        .mask {
            // The scene owns the top of the page; only the bottom edge
            // dissolves into the app background.
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.94),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .animation(.easeInOut(duration: 0.8), value: season)
        .animation(.easeInOut(duration: 0.8), value: phase)
    }
}

// MARK: - Sky: sun, moon, stars, clouds

private struct WillowCelestialLayer: View {
    let season: WillowSeason
    let phase: WillowDayPhase
    let time: TimeInterval
    let size: CGSize

    var body: some View {
        ZStack {
            if phase == .night {
                starsView
                moon
            } else {
                sun
            }
            cloudsView
        }
        .frame(width: size.width, height: size.height)
    }

    private var sun: some View {
        let pulse = 1 + 0.04 * sin(time * 0.5)
        let warm = season == .winter
            ? Color(red: 0.95, green: 0.90, blue: 0.74)
            : Color(red: 0.96, green: 0.79, blue: 0.37)
        return ZStack {
            Circle()
                .fill(warm.opacity(0.18))
                .frame(width: 116)
                .blur(radius: 18)
            Circle()
                .fill(warm.opacity(0.42))
                .frame(width: 64)
                .blur(radius: 8)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.94, blue: 0.74), warm],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44)
        }
        .scaleEffect(pulse)
        .position(x: size.width * 0.82, y: size.height * 0.14)
    }

    private var moon: some View {
        let glow = Color(red: 0.95, green: 0.92, blue: 0.80)
        return ZStack {
            Circle()
                .fill(glow.opacity(0.16))
                .frame(width: 92)
                .blur(radius: 14)
            ZStack {
                Circle()
                    .fill(glow)
                Circle()
                    .fill(season.skyColors(for: .night)[0])
                    .offset(x: 10, y: -7)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        }
        .position(x: size.width * 0.80, y: size.height * 0.14)
    }

    private static let starField: [(x: CGFloat, y: CGFloat, r: CGFloat, p: Double)] = [
        (0.08, 0.10, 1.6, 0.0), (0.16, 0.22, 1.2, 1.3), (0.24, 0.07, 1.8, 2.6),
        (0.31, 0.16, 1.1, 0.8), (0.40, 0.09, 1.5, 3.9), (0.47, 0.20, 1.2, 1.9),
        (0.55, 0.06, 1.7, 4.7), (0.62, 0.14, 1.2, 2.4), (0.68, 0.24, 1.5, 0.5),
        (0.88, 0.30, 1.3, 3.1), (0.93, 0.12, 1.6, 1.1), (0.13, 0.33, 1.2, 5.0),
        (0.35, 0.30, 1.0, 2.0), (0.52, 0.33, 1.3, 4.2), (0.83, 0.05, 1.2, 0.2),
        (0.97, 0.40, 1.0, 5.4)
    ]

    private var starsView: some View {
        ForEach(0..<Self.starField.count, id: \.self) { index in
            let star = Self.starField[index]
            let twinkle = 0.45 + 0.55 * (sin(time * 1.4 + star.p) + 1) / 2
            Circle()
                .fill(.white.opacity(0.85 * twinkle))
                .frame(width: star.r * 2, height: star.r * 2)
                .position(x: size.width * star.x, y: size.height * star.y)
        }
    }

    private static let cloudConfigs: [(y: CGFloat, scale: CGFloat, speed: Double, seed: Double)] = [
        (0.13, 1.0, 9, 0.0),
        (0.27, 0.76, 13, 0.45),
        (0.06, 0.60, 6, 0.80)
    ]

    private var cloudsView: some View {
        ForEach(0..<Self.cloudConfigs.count, id: \.self) { index in
            let config = Self.cloudConfigs[index]
            let span = Double(size.width) + 180
            let x = CGFloat((time * config.speed + config.seed * span).truncatingRemainder(dividingBy: span)) - 90
            WillowCloudPuff()
                .scaleEffect(config.scale)
                .opacity(cloudOpacity)
                .position(x: x, y: size.height * config.y)
        }
    }

    private var cloudOpacity: Double {
        if phase == .night { return 0.12 }
        return season == .winter ? 0.95 : 0.80
    }
}

private struct WillowCloudPuff: View {
    var body: some View {
        ZStack {
            Ellipse()
                .frame(width: 86, height: 26)
            Circle()
                .frame(width: 34)
                .offset(x: -16, y: -10)
            Circle()
                .frame(width: 26)
                .offset(x: 15, y: -8)
        }
        .foregroundStyle(.white)
        .blur(radius: 1.5)
    }
}

// MARK: - Ground

private struct WillowGroundView: View {
    let season: WillowSeason
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            WillowGroundShape()
                .fill(
                    LinearGradient(
                        colors: [season.groundLight, season.groundShade],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 88)
            details
        }
        .frame(width: width, alignment: .bottom)
    }

    @ViewBuilder private var details: some View {
        backgroundTufts
        switch season {
        case .spring:
            flowers(at: [(0.10, 16), (0.21, 32), (0.34, 12), (0.63, 14), (0.80, 30), (0.91, 14)])
        case .summer:
            flowers(at: [(0.14, 20), (0.68, 12), (0.86, 24)])
        case .autumn:
            fallenLeaves
        case .winter:
            snowDrifts
        }
    }

    /// Distant tufts are smaller and sit higher on the mound so the
    /// scattering reads with believable depth.
    private var backgroundTufts: some View {
        ForEach(0..<5, id: \.self) { index in
            let configs: [(x: CGFloat, lift: CGFloat, w: CGFloat)] = [
                (0.07, 22, 16), (0.24, 38, 12), (0.50, 42, 11), (0.72, 36, 13), (0.94, 20, 17)
            ]
            let config = configs[index]
            WillowGrassTuft(season: season, width: config.w)
                .offset(x: width * config.x - width / 2, y: -config.lift)
        }
    }

    private func flowers(at positions: [(x: CGFloat, lift: CGFloat)]) -> some View {
        ForEach(0..<positions.count, id: \.self) { index in
            let spot = positions[index]
            flower(index: index)
                .offset(x: width * spot.x - width / 2, y: -spot.lift)
        }
    }

    private func flower(index: Int) -> some View {
        let colors: [Color] = [
            Color(red: 0.95, green: 0.72, blue: 0.76),
            Color(red: 0.98, green: 0.95, blue: 0.88),
            Color(red: 0.96, green: 0.82, blue: 0.49)
        ]
        return ZStack {
            Circle()
                .fill(colors[index % colors.count])
                .frame(width: 6, height: 6)
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 2.2, height: 2.2)
        }
    }

    private var fallenLeaves: some View {
        ForEach(0..<6, id: \.self) { index in
            let xs: [CGFloat] = [0.08, 0.20, 0.36, 0.60, 0.78, 0.92]
            let lifts: [CGFloat] = [10, 26, 8, 12, 24, 10]
            let angles: [Double] = [78, 104, 88, 70, 96, 110]
            let color = index.isMultiple(of: 2)
                ? Color(red: 0.79, green: 0.56, blue: 0.25)
                : Color(red: 0.62, green: 0.42, blue: 0.22)
            LeafShape()
                .fill(color.opacity(0.85))
                .frame(width: 9, height: 16)
                .rotationEffect(.degrees(angles[index]))
                .offset(x: width * xs[index] - width / 2, y: -lifts[index])
        }
    }

    private var snowDrifts: some View {
        ForEach(0..<3, id: \.self) { index in
            let xs: [CGFloat] = [0.16, 0.55, 0.86]
            let widths: [CGFloat] = [70, 90, 56]
            Ellipse()
                .fill(.white.opacity(0.65))
                .frame(width: widths[index], height: 14)
                .blur(radius: 4)
                .offset(x: width * xs[index] - width / 2, y: -4)
        }
    }
}

/// Large grass tufts at the very front edge of the scene, drawn over the
/// content for a sense of depth. Positioned away from where the
/// companions stand.
private struct WillowForegroundView: View {
    let season: WillowSeason
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            tuft(x: 0.30, w: 34, lift: 2)
            tuft(x: 0.55, w: 28, lift: 5)
            tuft(x: 0.76, w: 36, lift: 1)
        }
        .frame(width: width, alignment: .bottom)
    }

    private func tuft(x: CGFloat, w: CGFloat, lift: CGFloat) -> some View {
        WillowGrassTuft(season: season, width: w)
            .offset(x: width * x - width / 2, y: -lift)
    }
}

// MARK: - Grass

/// A small clump of curved grass blades that follows the seasons:
/// fresh green in spring, lush in summer, dry olive in autumn, and pale
/// with a snow cap in winter. Shared by the scene ground and the tree base.
struct WillowGrassTuft: View {
    let season: WillowSeason
    var width: CGFloat = 24

    var body: some View {
        ZStack(alignment: .bottom) {
            blades
            if season == .winter {
                snowCap
            }
        }
        .frame(width: width, height: width * 0.66, alignment: .bottom)
    }

    private var blades: some View {
        ForEach(0..<5, id: \.self) { index in
            let angles: [Double] = [-26, -12, 0, 13, 27]
            let heights: [CGFloat] = [0.62, 0.85, 1.0, 0.80, 0.58]
            GrassBladeShape()
                .fill(bladeColors[index % bladeColors.count])
                .frame(width: width * 0.16, height: width * 0.62 * heights[index])
                .rotationEffect(.degrees(angles[index]), anchor: .bottom)
        }
    }

    private var snowCap: some View {
        ZStack {
            Ellipse()
                .fill(.white.opacity(0.88))
                .frame(width: width * 0.78, height: width * 0.22)
                .offset(y: -width * 0.34)
            Ellipse()
                .fill(.white.opacity(0.75))
                .frame(width: width * 0.42, height: width * 0.16)
                .offset(x: width * 0.10, y: -width * 0.48)
        }
    }

    private var bladeColors: [Color] {
        switch season {
        case .spring:
            [Color(red: 0.55, green: 0.74, blue: 0.42), Color(red: 0.62, green: 0.80, blue: 0.48), Color(red: 0.49, green: 0.68, blue: 0.38)]
        case .summer:
            [Color(red: 0.42, green: 0.63, blue: 0.31), Color(red: 0.50, green: 0.70, blue: 0.38), Color(red: 0.38, green: 0.58, blue: 0.29)]
        case .autumn:
            [Color(red: 0.66, green: 0.58, blue: 0.33), Color(red: 0.73, green: 0.65, blue: 0.38), Color(red: 0.58, green: 0.50, blue: 0.30)]
        case .winter:
            [Color(red: 0.62, green: 0.68, blue: 0.64), Color(red: 0.70, green: 0.76, blue: 0.72), Color(red: 0.55, green: 0.62, blue: 0.60)]
        }
    }
}

/// Single curved, tapered grass blade.
struct GrassBladeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.10, y: rect.minY),
            control: CGPoint(x: rect.midX - rect.width * 0.35, y: rect.height * 0.35)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX + rect.width * 0.45, y: rect.height * 0.45)
        )
        p.closeSubpath()
        return p
    }
}

private struct WillowGroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * 0.60))
        p.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.22),
            control1: CGPoint(x: w * 0.18, y: h * 0.55),
            control2: CGPoint(x: w * 0.32, y: h * 0.22)
        )
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.55),
            control1: CGPoint(x: w * 0.68, y: h * 0.22),
            control2: CGPoint(x: w * 0.84, y: h * 0.48)
        )
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

// MARK: - Particles

private struct WillowParticleLayer: View {
    let season: WillowSeason
    let phase: WillowDayPhase
    let time: TimeInterval
    let size: CGSize

    var body: some View {
        ZStack {
            switch season {
            case .spring:
                petals
            case .summer:
                if phase == .night {
                    fireflies
                }
            case .autumn:
                fallingLeaves
            case .winter:
                snow
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// Loops a particle from above the scene to below it, offset by seed.
    private func fallY(speed: Double, seed: Double) -> CGFloat {
        let span = Double(size.height) + 40
        return CGFloat((time * speed + seed * span).truncatingRemainder(dividingBy: span)) - 20
    }

    private static let petalConfigs: [(x: CGFloat, speed: Double, seed: Double)] = [
        (0.12, 13, 0.05), (0.30, 17, 0.42), (0.48, 12, 0.76),
        (0.64, 15, 0.20), (0.80, 11, 0.58), (0.93, 16, 0.90)
    ]

    private var petals: some View {
        ForEach(0..<Self.petalConfigs.count, id: \.self) { index in
            let config = Self.petalConfigs[index]
            let y = fallY(speed: config.speed, seed: config.seed)
            let sway = sin(time * 0.6 + config.seed * 9) * 14
            Ellipse()
                .fill(Color(red: 0.95, green: 0.74, blue: 0.78).opacity(0.85))
                .frame(width: 5, height: 7)
                .rotationEffect(.degrees(time * 50 + config.seed * 360))
                .position(x: size.width * config.x + sway, y: y)
        }
    }

    private static let leafConfigs: [(x: CGFloat, speed: Double, seed: Double)] = [
        (0.10, 20, 0.02), (0.24, 26, 0.36), (0.38, 18, 0.70), (0.52, 24, 0.14),
        (0.66, 21, 0.50), (0.78, 28, 0.84), (0.88, 19, 0.28), (0.97, 23, 0.62)
    ]

    private var fallingLeaves: some View {
        ForEach(0..<Self.leafConfigs.count, id: \.self) { index in
            let config = Self.leafConfigs[index]
            let y = fallY(speed: config.speed, seed: config.seed)
            let sway = sin(time * 0.7 + config.seed * 11) * 18
            let color = index.isMultiple(of: 2)
                ? Color(red: 0.83, green: 0.60, blue: 0.26)
                : Color(red: 0.69, green: 0.46, blue: 0.22)
            LeafShape()
                .fill(color.opacity(0.85))
                .frame(width: 8, height: 15)
                .rotationEffect(.degrees(time * 65 + config.seed * 360))
                .position(x: size.width * config.x + sway, y: y)
        }
    }

    private static let snowConfigs: [(x: CGFloat, speed: Double, r: CGFloat, seed: Double)] = [
        (0.05, 16, 2.0, 0.00), (0.13, 22, 1.5, 0.36), (0.21, 18, 2.4, 0.71),
        (0.30, 25, 1.6, 0.14), (0.38, 17, 2.1, 0.50), (0.47, 23, 1.4, 0.86),
        (0.55, 19, 2.3, 0.21), (0.63, 26, 1.6, 0.57), (0.71, 18, 2.0, 0.93),
        (0.79, 24, 1.5, 0.29), (0.86, 20, 2.2, 0.64), (0.93, 25, 1.5, 0.07),
        (0.50, 15, 1.2, 0.43), (0.97, 18, 1.8, 0.79)
    ]

    private var snow: some View {
        ForEach(0..<Self.snowConfigs.count, id: \.self) { index in
            let config = Self.snowConfigs[index]
            let y = fallY(speed: config.speed, seed: config.seed)
            let sway = sin(time * 0.8 + config.seed * 13) * 10
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: config.r * 2, height: config.r * 2)
                .position(x: size.width * config.x + sway, y: y)
        }
    }

    private static let fireflyConfigs: [(x: CGFloat, seed: Double)] = [
        (0.18, 0.0), (0.36, 1.7), (0.55, 3.1), (0.72, 4.4), (0.85, 5.9)
    ]

    private var fireflies: some View {
        ForEach(0..<Self.fireflyConfigs.count, id: \.self) { index in
            let config = Self.fireflyConfigs[index]
            let x = size.width * config.x + sin(time * 0.27 + config.seed * 5) * 34
            let y = size.height * (0.66 + 0.16 * sin(time * 0.21 + config.seed * 9))
            let pulse = (sin(time * 1.1 + config.seed * 6) + 1) / 2
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.45).opacity(0.5))
                    .frame(width: 10)
                    .blur(radius: 3)
                Circle()
                    .fill(Color(red: 1.0, green: 0.92, blue: 0.62))
                    .frame(width: 3.5)
            }
            .opacity(0.15 + pulse * 0.85)
            .position(x: x, y: y)
        }
    }
}

#Preview("Willow scene") {
    @Previewable @State var season: WillowSeason = .summer
    @Previewable @State var phase: WillowDayPhase = .day

    return VStack(spacing: 16) {
        WillowSceneView(season: season, phase: phase) {
            WillowTreeView(state: .flourishing, season: season)
        }
        .frame(height: 430)

        HStack {
            Button("Season: \(season.title)") {
                withAnimation(.easeInOut(duration: 0.8)) { season = season.next }
            }
            Button(phase == .day ? "To night" : "To day") {
                withAnimation(.easeInOut(duration: 0.8)) { phase = phase.toggled }
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(Color(red: 0.98, green: 0.95, blue: 0.88))
}
