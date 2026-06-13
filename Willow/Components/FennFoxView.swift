import SwiftUI

// MARK: - Companion state

enum CompanionState {
    case calm
    case happy
    case tired
}

// MARK: - Fenn the fox

/// Fenn is drawn entirely in code from layered bezier shapes and driven by a
/// single `TimelineView` clock. All continuous motion is applied through
/// transforms (rotation / offset / scale) so path geometry is never rebuilt
/// per frame, and every oscillator uses a fixed frequency so there are no
/// phase discontinuities when his mood changes.
///
/// Interactions:
/// - Tap: anticipation squash, a small hop with stretch, bouncy landing,
///   a burst of sparkles and a fast tail wag.
/// - Touch and hold: petting. Eyes close into happy arcs, head nuzzles side
///   to side, blush deepens and little hearts float up.
struct FennFoxView: View {
    let state: CompanionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hopCount = 0
    @State private var isPetting = false
    @State private var excitement: Double = 0
    @State private var petTask: Task<Void, Never>?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 45, paused: reduceMotion)) { context in
            FennFoxFigure(
                pose: FennFoxPose(
                    state: state,
                    isPetting: isPetting,
                    excitement: excitement,
                    time: context.date.timeIntervalSinceReferenceDate
                )
            )
        }
        .keyframeAnimator(initialValue: CompanionHopPose(), trigger: hopCount) { content, hop in
            content
                .scaleEffect(x: hop.stretchX, y: hop.stretchY, anchor: .bottom)
                .offset(y: hop.lift)
        } keyframes: { _ in
            KeyframeTrack(\.lift) {
                CubicKeyframe(2, duration: 0.09)      // anticipation crouch
                CubicKeyframe(-15, duration: 0.17)    // hop
                CubicKeyframe(0, duration: 0.14)      // land
                SpringKeyframe(0, spring: .bouncy)    // settle
            }
            KeyframeTrack(\.stretchY) {
                CubicKeyframe(0.85, duration: 0.09)   // squash down
                CubicKeyframe(1.09, duration: 0.16)   // stretch in the air
                CubicKeyframe(0.91, duration: 0.13)   // landing squash
                SpringKeyframe(1.0, spring: .bouncy)
            }
            KeyframeTrack(\.stretchX) {
                CubicKeyframe(1.11, duration: 0.09)
                CubicKeyframe(0.94, duration: 0.16)
                CubicKeyframe(1.06, duration: 0.13)
                SpringKeyframe(1.0, spring: .bouncy)
            }
        }
        .frame(width: 120, height: 124)
        .contentShape(Rectangle())
        .onTapGesture(perform: hop)
        .onLongPressGesture(minimumDuration: 0.4, maximumDistance: 30) {
        } onPressingChanged: { pressing in
            handlePressing(pressing)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hopCount)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: isPetting) { _, began in began }
        .accessibilityElement()
        .accessibilityLabel("Fenn the fox, feeling \(moodDescription)")
        .accessibilityHint("Tap to play with Fenn, touch and hold to pet him")
        .accessibilityAddTraits(.isButton)
        .onDisappear { petTask?.cancel() }
    }

    private var moodDescription: String {
        switch state {
        case .calm: "calm"
        case .happy: "happy"
        case .tired: "tired"
        }
    }

    private func hop() {
        hopCount += 1
        let current = hopCount
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { excitement = 1 }
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard hopCount == current else { return }
            withAnimation(.easeOut(duration: 0.9)) { excitement = 0 }
        }
    }

    private func handlePressing(_ pressing: Bool) {
        petTask?.cancel()
        if pressing {
            // Small delay so quick taps don't flash the petting pose.
            petTask = Task {
                try? await Task.sleep(for: .seconds(0.28))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.25)) { isPetting = true }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { isPetting = false }
        }
    }
}

// MARK: - Hop keyframe value (shared by all bespoke companions)

struct CompanionHopPose {
    var lift: CGFloat = 0
    var stretchX: CGFloat = 1
    var stretchY: CGFloat = 1
}

// MARK: - Pose (the animation rig)

/// Computes every animated parameter from wall-clock time plus mood and
/// interaction state. Each oscillator has a constant frequency; moods and
/// excitement only blend amplitudes and rest values, which keeps motion
/// continuous and lets one-off mood changes be spring-animated.
struct FennFoxPose {
    let state: CompanionState
    let isPetting: Bool
    let excitement: Double
    let time: TimeInterval

    var showsHappyArcs: Bool { isPetting }

    // Slow torso breathing, faster when happy, slower when tired.
    var breath: Double {
        let period: Double = switch state {
        case .calm: 3.4
        case .happy: 2.6
        case .tired: 4.6
        }
        return sin(time * 2 * .pi / period)
    }

    // Resting tail angle by mood + idle sway + a fast wag layered on top
    // while excited. Frequencies are constant so blending never jumps.
    var tailAngle: Double {
        let base: Double = switch state {
        case .calm: -14
        case .happy: -7
        case .tired: -26
        }
        let idleAmplitude: Double = state == .happy ? 6.5 : 3.0
        let idleFrequency: Double = state == .happy ? 0.8 : 0.45
        let idle = idleAmplitude * sin(time * 2 * .pi * idleFrequency)
        let wag = excitement * 8 * sin(time * 2 * .pi * 2.3)
        let pet = isPetting ? 3 * sin(time * 2 * .pi * 0.5) : 0
        return base + idle + wag + pet
    }

    // Positive folds ears outward (tired), negative perks them up.
    var earDroop: Double {
        let base: Double = switch state {
        case .calm: 0
        case .happy: -2
        case .tired: 13
        }
        return base - excitement * 5
    }

    // Occasional asymmetric ear flicks make him feel alive between blinks.
    private func earTwitch(seed: Double, period: Double) -> Double {
        let phase = (time + seed).truncatingRemainder(dividingBy: period)
        guard phase < 0.4 else { return 0 }
        return sin(.pi * phase / 0.4) * sin(phase * .pi * 10) * 6
    }

    var earTwitchLeft: Double { earTwitch(seed: 0, period: 7.3) }
    var earTwitchRight: Double { earTwitch(seed: 3.7, period: 9.1) }

    private var blink: Double {
        guard !isPetting else { return 0 }
        let period: Double = switch state {
        case .calm: 4.6
        case .happy: 3.8
        case .tired: 6.4
        }
        let phase = (time + 1.2).truncatingRemainder(dividingBy: period)
        let duration = 0.18
        guard phase < duration else { return 0 }
        return sin(.pi * phase / duration)
    }

    var eyeOpenness: Double {
        let base: Double = switch state {
        case .calm: 1.0
        case .happy: 0.95
        case .tired: 0.55
        }
        return base * (1 - blink)
    }

    // Slow gaze drift so the eyes never feel frozen.
    var eyeDrift: CGFloat {
        guard !isPetting else { return 0 }
        return CGFloat(sin(time * 2 * .pi / 9) * 1.3)
    }

    var headTilt: Double {
        let nuzzle = isPetting ? sin(time * 2 * .pi * 0.55) * 4 : 0
        let base: Double = switch state {
        case .calm: 0.6
        case .happy: -2.0
        case .tired: 2.4
        }
        return base + nuzzle - excitement * 1.5
    }

    // Positive sits the head lower (tired slump); breathing bobs it gently.
    var headLiftY: CGFloat {
        let drop: CGFloat = switch state {
        case .calm: 0
        case .happy: -1.5
        case .tired: 5
        }
        return drop + CGFloat(-breath * 1.4) + CGFloat(excitement * -2)
    }

    var smile: CGFloat {
        if isPetting { return 1.25 }
        let base: CGFloat = switch state {
        case .calm: 0.45
        case .happy: 1.0
        case .tired: 0.05
        }
        return base + CGFloat(excitement) * 0.4
    }

    var blushOpacity: Double {
        if isPetting { return 0.55 }
        return state == .happy ? 0.32 : 0.18
    }

    var sparkleStrength: Double {
        min(1.2, (state == .happy ? 0.65 : 0) + excitement * 0.9)
    }
}

// MARK: - Palette

private enum FennPalette {
    static let coat = Color(red: 0.91, green: 0.56, blue: 0.24)
    static let coatLight = Color(red: 0.96, green: 0.68, blue: 0.34)
    static let coatDeep = Color(red: 0.76, green: 0.42, blue: 0.17)
    static let cream = Color(red: 0.99, green: 0.92, blue: 0.78)
    static let earInner = Color(red: 0.99, green: 0.90, blue: 0.74)
    static let ink = Color(red: 0.17, green: 0.11, blue: 0.08)
    static let blushPink = Color(red: 0.94, green: 0.52, blue: 0.42)
    static let bandana = Color(red: 0.58, green: 0.67, blue: 0.44)
    static let bandanaDeep = Color(red: 0.42, green: 0.53, blue: 0.34)
    static let grass = Color(red: 0.78, green: 0.85, blue: 0.62)
    static let sprig = Color(red: 0.60, green: 0.72, blue: 0.46)
    static let sparkle = Color(red: 0.96, green: 0.80, blue: 0.45)
    static let shadow = Color(red: 0.28, green: 0.36, blue: 0.25)
}

// MARK: - Figure

private struct FennFoxFigure: View {
    let pose: FennFoxPose

    var body: some View {
        ZStack(alignment: .bottom) {
            grassBed
            groundShadow
            tail
            torso
            bandana
            headGroup
            emotes
        }
        .frame(width: 120, height: 124, alignment: .bottom)
        .saturation(pose.state == .tired ? 0.80 : 1)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pose.state)
    }

    // MARK: Ground

    private var grassBed: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(FennPalette.grass.opacity(0.55))
                .frame(width: 104, height: 18)
                .offset(y: 2)
            LeafShape()
                .fill(FennPalette.sprig.opacity(0.8))
                .frame(width: 7, height: 15)
                .rotationEffect(.degrees(-22), anchor: .bottom)
                .offset(x: -46, y: -3)
            LeafShape()
                .fill(FennPalette.sprig.opacity(0.7))
                .frame(width: 6, height: 13)
                .rotationEffect(.degrees(18), anchor: .bottom)
                .offset(x: 47, y: -3)
            LeafShape()
                .fill(FennPalette.sprig.opacity(0.55))
                .frame(width: 5, height: 10)
                .rotationEffect(.degrees(32), anchor: .bottom)
                .offset(x: 40, y: -2)
        }
    }

    private var groundShadow: some View {
        Ellipse()
            .fill(FennPalette.shadow.opacity(0.16))
            .frame(width: 62, height: 9)
            .blur(radius: 3)
            .offset(y: -2)
    }

    // MARK: Tail

    private var tail: some View {
        FennFoxTailShape()
            .fill(
                LinearGradient(
                    colors: [FennPalette.coat, FennPalette.coatDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 86)
            .overlay {
                Ellipse()
                    .fill(FennPalette.cream.opacity(0.95))
                    .frame(width: 46, height: 42)
                    .offset(x: -1, y: -27)
            }
            .clipShape(FennFoxTailShape())
            .rotationEffect(.degrees(pose.tailAngle), anchor: UnitPoint(x: 0.9, y: 0.96))
            .offset(x: -30, y: -6)
    }

    // MARK: Body

    private var torso: some View {
        ZStack(alignment: .bottom) {
            FennFoxBodyShape()
                .fill(
                    LinearGradient(
                        colors: [FennPalette.coatLight, FennPalette.coat],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 64, height: 58)
                .overlay {
                    ZStack {
                        Ellipse()
                            .fill(FennPalette.coatDeep.opacity(0.28))
                            .frame(width: 22, height: 30)
                            .offset(x: -24, y: 16)
                        Ellipse()
                            .fill(FennPalette.coatDeep.opacity(0.28))
                            .frame(width: 22, height: 30)
                            .offset(x: 24, y: 16)
                        Ellipse()
                            .fill(FennPalette.cream.opacity(0.95))
                            .frame(width: 34, height: 44)
                            .offset(y: 12)
                    }
                }
                .clipShape(FennFoxBodyShape())

            HStack(spacing: 7) {
                paw
                paw
            }
            .offset(y: -2)
        }
        .offset(x: 2)
        .scaleEffect(x: 1, y: 1 + 0.016 * pose.breath, anchor: .bottom)
    }

    private var paw: some View {
        Capsule()
            .fill(FennPalette.cream)
            .overlay {
                Capsule()
                    .strokeBorder(FennPalette.coatDeep.opacity(0.30), lineWidth: 1)
            }
            .frame(width: 13, height: 9)
    }

    private var bandana: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(FennPalette.bandanaDeep)
                .frame(width: 40, height: 10)
                .offset(y: -45)
            FennFoxBandanaShape()
                .fill(
                    LinearGradient(
                        colors: [FennPalette.bandana, FennPalette.bandanaDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 24)
                .overlay {
                    LeafShape()
                        .fill(FennPalette.cream.opacity(0.30))
                        .frame(width: 6, height: 10)
                        .rotationEffect(.degrees(20))
                        .offset(y: -2)
                }
                .offset(x: 5, y: -25)
        }
        .offset(x: 1)
    }

    // MARK: Head

    private var headGroup: some View {
        ZStack(alignment: .bottom) {
            ear(isLeft: true).offset(x: -25, y: -44)
            ear(isLeft: false).offset(x: 25, y: -44)
            headShape
            faceView
        }
        .frame(width: 86, height: 98, alignment: .bottom)
        .rotationEffect(.degrees(pose.headTilt), anchor: UnitPoint(x: 0.5, y: 0.85))
        .offset(x: 1, y: -42 + pose.headLiftY)
    }

    private func ear(isLeft: Bool) -> some View {
        let side: Double = isLeft ? -1 : 1
        let twitch = isLeft ? pose.earTwitchLeft : pose.earTwitchRight
        let angle = side * (15 + pose.earDroop) + twitch
        return FennFoxEarShape()
            .fill(
                LinearGradient(
                    colors: [FennPalette.coat, FennPalette.coatDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 25, height: 31)
            .overlay {
                FennFoxEarShape()
                    .fill(FennPalette.earInner.opacity(0.9))
                    .frame(width: 12, height: 16)
                    .offset(y: 6)
            }
            .rotationEffect(.degrees(angle), anchor: .bottom)
    }

    private var headShape: some View {
        FennFoxHeadShape()
            .fill(
                LinearGradient(
                    colors: [FennPalette.coatLight, FennPalette.coat],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
            )
            .frame(width: 80, height: 58)
            .overlay {
                ZStack {
                    Ellipse()
                        .fill(FennPalette.cream.opacity(0.96))
                        .frame(width: 34, height: 25)
                        .offset(x: -15, y: 17)
                    Ellipse()
                        .fill(FennPalette.cream.opacity(0.96))
                        .frame(width: 34, height: 25)
                        .offset(x: 15, y: 17)
                }
            }
            .clipShape(FennFoxHeadShape())
    }

    private var faceView: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 22) {
                eye
                eye
            }
            .offset(x: pose.eyeDrift, y: -28)

            FennFoxNoseShape()
                .fill(FennPalette.ink.opacity(0.95))
                .frame(width: 8, height: 6)
                .offset(y: -21)

            FennFoxMouthShape(lift: -0.5 + pose.smile * 2.4)
                .stroke(
                    FennPalette.ink.opacity(0.70),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: 16, height: 8)
                .offset(y: -14)

            HStack(spacing: 48) {
                blushDot
                blushDot
            }
            .offset(y: -19)
        }
    }

    @ViewBuilder private var eye: some View {
        if pose.showsHappyArcs {
            FennHappyEyeShape()
                .stroke(FennPalette.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .frame(width: 11, height: 6)
                .padding(.vertical, 4)
        } else {
            ZStack {
                Ellipse()
                    .fill(FennPalette.ink)
                Circle()
                    .fill(.white.opacity(0.92))
                    .frame(width: 3.8)
                    .offset(x: -2.2, y: -3.2)
                Circle()
                    .fill(.white.opacity(0.70))
                    .frame(width: 2)
                    .offset(x: 2.5, y: 3)
            }
            .frame(width: 12, height: 14)
            .scaleEffect(x: 1, y: max(0.12, pose.eyeOpenness), anchor: .center)
        }
    }

    private var blushDot: some View {
        Ellipse()
            .fill(FennPalette.blushPink.opacity(pose.blushOpacity))
            .frame(width: 10, height: 6)
    }

    // MARK: Emotes

    @ViewBuilder private var emotes: some View {
        if pose.sparkleStrength > 0.04 {
            sparkle(size: 9, x: -46, y: -96, phase: 0)
            sparkle(size: 7, x: 43, y: -84, phase: 2.1)
            sparkle(size: 6, x: -37, y: -34, phase: 4.2)
        }
        if pose.isPetting {
            heart(x: -33, y: -88, seed: 0)
            heart(x: 37, y: -94, seed: 0.55)
        }
        if pose.state == .tired && !pose.isPetting {
            snore(x: 36, y: -96, size: 10, seed: 0)
            snore(x: 45, y: -106, size: 13, seed: 0.5)
        }
    }

    private func sparkle(size: CGFloat, x: CGFloat, y: CGFloat, phase: Double) -> some View {
        let twinkle = (sin(pose.time * 2.4 + phase) + 1) / 2
        return FennSparkleShape()
            .fill(FennPalette.sparkle)
            .frame(width: size, height: size)
            .scaleEffect(0.7 + twinkle * 0.5 + pose.excitement * 0.4)
            .opacity(pose.sparkleStrength * (0.35 + twinkle * 0.65))
            .offset(x: x, y: y)
    }

    private func heart(x: CGFloat, y: CGFloat, seed: Double) -> some View {
        let phase = (pose.time * 0.7 + seed).truncatingRemainder(dividingBy: 1)
        return Image(systemName: "heart.fill")
            .font(.system(size: 9))
            .foregroundStyle(FennPalette.blushPink.opacity((1 - phase) * 0.9))
            .scaleEffect(0.7 + phase * 0.5)
            .offset(x: x + sin(phase * 2 * .pi) * 3, y: y - phase * 20)
    }

    private func snore(x: CGFloat, y: CGFloat, size: CGFloat, seed: Double) -> some View {
        let phase = (pose.time * 0.4 + seed).truncatingRemainder(dividingBy: 1)
        return Text("z")
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(FennPalette.coatDeep.opacity((1 - phase) * 0.6))
            .offset(x: x + phase * 5, y: y - phase * 14)
    }
}

// MARK: - Shapes

struct FennFoxBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.78),
            control1: CGPoint(x: w * 0.84, y: h * 0.02),
            control2: CGPoint(x: w, y: h * 0.40)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.78, y: h),
            control1: CGPoint(x: w, y: h * 0.92),
            control2: CGPoint(x: w * 0.90, y: h)
        )
        p.addLine(to: CGPoint(x: w * 0.22, y: h))
        p.addCurve(
            to: CGPoint(x: 0, y: h * 0.78),
            control1: CGPoint(x: w * 0.10, y: h),
            control2: CGPoint(x: 0, y: h * 0.92)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: 0, y: h * 0.40),
            control2: CGPoint(x: w * 0.16, y: h * 0.02)
        )
        p.closeSubpath()
        return p
    }
}

/// Wide head with two small fur tufts on each cheek.
struct FennFoxHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.50, y: h * 0.04))
        p.addCurve(
            to: CGPoint(x: w * 0.97, y: h * 0.52),
            control1: CGPoint(x: w * 0.78, y: 0),
            control2: CGPoint(x: w * 0.97, y: h * 0.20)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.93, y: h * 0.68),
            control1: CGPoint(x: w * 0.97, y: h * 0.58),
            control2: CGPoint(x: w * 0.96, y: h * 0.63)
        )
        p.addLine(to: CGPoint(x: w * 0.99, y: h * 0.76))
        p.addCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.88),
            control1: CGPoint(x: w * 0.93, y: h * 0.84),
            control2: CGPoint(x: w * 0.88, y: h * 0.87)
        )
        p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.97))
        p.addCurve(
            to: CGPoint(x: w * 0.50, y: h),
            control1: CGPoint(x: w * 0.72, y: h * 0.99),
            control2: CGPoint(x: w * 0.60, y: h)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.16, y: h * 0.97),
            control1: CGPoint(x: w * 0.40, y: h),
            control2: CGPoint(x: w * 0.28, y: h * 0.99)
        )
        p.addLine(to: CGPoint(x: w * 0.20, y: h * 0.88))
        p.addCurve(
            to: CGPoint(x: w * 0.01, y: h * 0.76),
            control1: CGPoint(x: w * 0.12, y: h * 0.87),
            control2: CGPoint(x: w * 0.07, y: h * 0.84)
        )
        p.addLine(to: CGPoint(x: w * 0.07, y: h * 0.68))
        p.addCurve(
            to: CGPoint(x: w * 0.03, y: h * 0.52),
            control1: CGPoint(x: w * 0.04, y: h * 0.63),
            control2: CGPoint(x: w * 0.03, y: h * 0.58)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.04),
            control1: CGPoint(x: w * 0.03, y: h * 0.20),
            control2: CGPoint(x: w * 0.22, y: 0)
        )
        p.closeSubpath()
        return p
    }
}

struct FennFoxEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.50, y: 0))
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.94),
            control1: CGPoint(x: w * 0.86, y: h * 0.22),
            control2: CGPoint(x: w, y: h * 0.66)
        )
        p.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.94),
            control: CGPoint(x: w * 0.5, y: h * 1.10)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.50, y: 0),
            control1: CGPoint(x: 0, y: h * 0.66),
            control2: CGPoint(x: w * 0.14, y: h * 0.22)
        )
        p.closeSubpath()
        return p
    }
}

/// Tall plume curling up beside the body, base anchored bottom-right.
struct FennFoxTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.95, y: h * 0.97))
        p.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.62),
            control1: CGPoint(x: w * 0.55, y: h * 1.02),
            control2: CGPoint(x: w * 0.22, y: h * 0.88)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.30, y: h * 0.14),
            control1: CGPoint(x: w * 0.12, y: h * 0.40),
            control2: CGPoint(x: w * 0.16, y: h * 0.24)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.68, y: h * 0.02),
            control1: CGPoint(x: w * 0.42, y: h * 0.05),
            control2: CGPoint(x: w * 0.56, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.50),
            control1: CGPoint(x: w * 0.84, y: h * 0.08),
            control2: CGPoint(x: w * 0.92, y: h * 0.28)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.97),
            control1: CGPoint(x: w * 0.84, y: h * 0.72),
            control2: CGPoint(x: w * 0.90, y: h * 0.88)
        )
        p.closeSubpath()
        return p
    }
}

/// Hanging kerchief triangle with a softly curved point.
struct FennFoxBandanaShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.02, y: h * 0.08))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.98, y: h * 0.08),
            control: CGPoint(x: w * 0.50, y: h * 0.40)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.56, y: h),
            control1: CGPoint(x: w * 0.88, y: h * 0.45),
            control2: CGPoint(x: w * 0.72, y: h * 0.82)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.02, y: h * 0.08),
            control1: CGPoint(x: w * 0.40, y: h * 0.80),
            control2: CGPoint(x: w * 0.12, y: h * 0.42)
        )
        p.closeSubpath()
        return p
    }
}

/// Soft rounded triangle nose pointing down.
struct FennFoxNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.08, y: h * 0.18))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.18),
            control: CGPoint(x: w * 0.50, y: -h * 0.10)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h),
            control: CGPoint(x: w * 0.92, y: h * 0.72)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.08, y: h * 0.18),
            control: CGPoint(x: w * 0.08, y: h * 0.72)
        )
        p.closeSubpath()
        return p
    }
}

/// Little "w" mouth; `lift` raises the corners into a smile.
struct FennFoxMouthShape: Shape {
    var lift: CGFloat

    var animatableData: CGFloat {
        get { lift }
        set { lift = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY - lift),
            control: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.midY + 2)
        )
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY - lift),
            control: CGPoint(x: rect.midX + rect.width * 0.16, y: rect.midY + 2)
        )
        return p
    }
}

/// Closed, contented eye arc used while petting.
struct FennHappyEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.3)
        )
        return p
    }
}

/// Four-point twinkle star.
struct FennSparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.32
        var p = Path()
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 {
                p.move(to: point)
            } else {
                p.addLine(to: point)
            }
        }
        p.closeSubpath()
        return p
    }
}

#Preview("Fenn states") {
    HStack(spacing: 24) {
        FennFoxView(state: .calm)
        FennFoxView(state: .happy)
        FennFoxView(state: .tired)
    }
    .padding(40)
    .background(Color(red: 0.98, green: 0.95, blue: 0.88))
}
