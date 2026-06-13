import SwiftUI

// MARK: - Luma the bunny

/// Luma is built with the same architecture as Fenn: layered bezier shapes
/// driven by a single `TimelineView` clock, with all continuous motion
/// applied through transforms at constant oscillator frequencies.
///
/// Character notes (from the design sheet):
/// - Soft long ears with slight asymmetry that sway gently and flick now
///   and then; they perk when happy and fold right down when tired.
/// - Tiny raised front paws held at the chest.
/// - A signature nose twitch every few seconds.
/// - Happy state adds a tiny idle bounce.
///
/// Interactions match Fenn: tap for a squash-and-stretch hop with sparkles,
/// touch and hold to pet (closed happy eyes, nuzzle, blush, hearts).
struct LumaBunnyView: View {
    let state: CompanionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hopCount = 0
    @State private var isPetting = false
    @State private var excitement: Double = 0
    @State private var petTask: Task<Void, Never>?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 45, paused: reduceMotion)) { context in
            LumaBunnyFigure(
                pose: LumaBunnyPose(
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
            // Bunnies hop a little higher than foxes.
            KeyframeTrack(\.lift) {
                CubicKeyframe(2, duration: 0.09)      // anticipation crouch
                CubicKeyframe(-18, duration: 0.18)    // hop
                CubicKeyframe(0, duration: 0.14)      // land
                SpringKeyframe(0, spring: .bouncy)    // settle
            }
            KeyframeTrack(\.stretchY) {
                CubicKeyframe(0.84, duration: 0.09)   // squash down
                CubicKeyframe(1.10, duration: 0.17)   // stretch in the air
                CubicKeyframe(0.90, duration: 0.13)   // landing squash
                SpringKeyframe(1.0, spring: .bouncy)
            }
            KeyframeTrack(\.stretchX) {
                CubicKeyframe(1.12, duration: 0.09)
                CubicKeyframe(0.93, duration: 0.17)
                CubicKeyframe(1.07, duration: 0.13)
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
        .accessibilityLabel("Luma the bunny, feeling \(moodDescription)")
        .accessibilityHint("Tap to play with Luma, touch and hold to pet her")
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

// MARK: - Pose (the animation rig)

struct LumaBunnyPose {
    let state: CompanionState
    let isPetting: Bool
    let excitement: Double
    let time: TimeInterval

    var showsHappyArcs: Bool { isPetting }

    // Slightly slower, gentler breathing than Fenn.
    var breath: Double {
        let period: Double = switch state {
        case .calm: 3.6
        case .happy: 2.8
        case .tired: 4.8
        }
        return sin(time * 2 * .pi / period)
    }

    // "Tiny bounce" idle from the happy state on the design sheet.
    var bounce: CGFloat {
        guard state == .happy, !isPetting else { return 0 }
        return CGFloat(abs(sin(time * 2 * .pi * 0.75)) * 1.8)
    }

    // Positive folds the long ears down and out (tired lop ears),
    // negative perks them up.
    var earDroop: Double {
        let base: Double = switch state {
        case .calm: 0
        case .happy: -3
        case .tired: 34
        }
        return base - excitement * 6
    }

    // Long ears always sway a little; excitement adds a fast wiggle.
    func earSway(side: Double) -> Double {
        let idle = sin(time * 2 * .pi * 0.4 + side * 1.2) * 1.5
        let wiggle = excitement * 4 * sin(time * 2 * .pi * 2.5 + side)
        return idle + wiggle
    }

    private func earFlick(seed: Double, period: Double) -> Double {
        let phase = (time + seed).truncatingRemainder(dividingBy: period)
        guard phase < 0.4 else { return 0 }
        return sin(.pi * phase / 0.4) * sin(phase * .pi * 10) * 7
    }

    var earFlickLeft: Double { earFlick(seed: 1.1, period: 5.7) }
    var earFlickRight: Double { earFlick(seed: 4.6, period: 8.3) }

    // Signature bunny nose wiggle every few seconds.
    var noseTwitch: Double {
        let phase = (time + 2.0).truncatingRemainder(dividingBy: 5.3)
        guard phase < 0.5 else { return 0 }
        return sin(.pi * phase / 0.5) * sin(phase * .pi * 14)
    }

    private var blink: Double {
        guard !isPetting else { return 0 }
        let period: Double = switch state {
        case .calm: 4.8
        case .happy: 4.0
        case .tired: 6.6
        }
        let phase = (time + 0.7).truncatingRemainder(dividingBy: period)
        let duration = 0.18
        guard phase < duration else { return 0 }
        return sin(.pi * phase / duration)
    }

    var eyeOpenness: Double {
        let base: Double = switch state {
        case .calm: 1.0
        case .happy: 0.95
        case .tired: 0.45
        }
        return base * (1 - blink)
    }

    var eyeDrift: CGFloat {
        guard !isPetting else { return 0 }
        return CGFloat(sin(time * 2 * .pi / 10) * 1.2)
    }

    var headTilt: Double {
        let nuzzle = isPetting ? sin(time * 2 * .pi * 0.55) * 4 : 0
        let base: Double = switch state {
        case .calm: 0.4
        case .happy: -1.5
        case .tired: 3.0
        }
        return base + nuzzle - excitement * 1.5
    }

    var headLiftY: CGFloat {
        let drop: CGFloat = switch state {
        case .calm: 0
        case .happy: -1
        case .tired: 6
        }
        return drop + CGFloat(-breath * 1.2) + CGFloat(excitement * -2)
    }

    var torsoSquash: CGFloat {
        state == .tired ? 0.96 : 1
    }

    var smile: CGFloat {
        if isPetting { return 1.2 }
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

// MARK: - Palette (hex values from the design sheet)

private enum LumaPalette {
    static let fur = Color(red: 0.788, green: 0.725, blue: 0.651)       // #C9B9A6
    static let furLight = Color(red: 0.851, green: 0.796, blue: 0.729)
    static let furDeep = Color(red: 0.655, green: 0.588, blue: 0.510)
    static let cream = Color(red: 0.949, green: 0.910, blue: 0.851)     // #F2E8D9
    static let earInner = Color(red: 0.910, green: 0.784, blue: 0.722)  // #E8C8B8
    static let pawNose = Color(red: 0.431, green: 0.365, blue: 0.310)   // #6E5D4F
    static let scarf = Color(red: 0.553, green: 0.667, blue: 0.478)     // #8DAA7A
    static let scarfDeep = Color(red: 0.42, green: 0.53, blue: 0.36)
    static let ink = Color(red: 0.18, green: 0.14, blue: 0.11)
    static let blushPink = Color(red: 0.91, green: 0.58, blue: 0.50)
    static let grass = Color(red: 0.78, green: 0.85, blue: 0.62)
    static let sprig = Color(red: 0.60, green: 0.72, blue: 0.46)
    static let sparkle = Color(red: 0.96, green: 0.80, blue: 0.45)
    static let shadow = Color(red: 0.28, green: 0.36, blue: 0.25)
}

// MARK: - Figure

private struct LumaBunnyFigure: View {
    let pose: LumaBunnyPose

    var body: some View {
        ZStack(alignment: .bottom) {
            grassBed
            groundShadow

            ZStack(alignment: .bottom) {
                tailPuff
                torso
                paws
                scarf
                headGroup
            }
            .offset(y: -pose.bounce)

            emotes
        }
        .frame(width: 120, height: 124, alignment: .bottom)
        .saturation(pose.state == .tired ? 0.82 : 1)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pose.state)
    }

    // MARK: Ground

    private var grassBed: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(LumaPalette.grass.opacity(0.55))
                .frame(width: 104, height: 18)
                .offset(y: 2)
            LeafShape()
                .fill(LumaPalette.sprig.opacity(0.8))
                .frame(width: 7, height: 15)
                .rotationEffect(.degrees(24), anchor: .bottom)
                .offset(x: 46, y: -3)
            LeafShape()
                .fill(LumaPalette.sprig.opacity(0.7))
                .frame(width: 6, height: 13)
                .rotationEffect(.degrees(-18), anchor: .bottom)
                .offset(x: -47, y: -3)
            LeafShape()
                .fill(LumaPalette.sprig.opacity(0.55))
                .frame(width: 5, height: 10)
                .rotationEffect(.degrees(-30), anchor: .bottom)
                .offset(x: -40, y: -2)
        }
    }

    private var groundShadow: some View {
        Ellipse()
            .fill(LumaPalette.shadow.opacity(0.16))
            .frame(width: 60, height: 9)
            .blur(radius: 3)
            .offset(y: -2)
    }

    // MARK: Body

    private var tailPuff: some View {
        Circle()
            .fill(LumaPalette.cream)
            .frame(width: 17, height: 17)
            .offset(x: -28, y: -7)
    }

    private var torso: some View {
        LumaBunnyBodyShape()
            .fill(
                LinearGradient(
                    colors: [LumaPalette.furLight, LumaPalette.fur],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 60, height: 54)
            .overlay {
                ZStack {
                    Ellipse()
                        .fill(LumaPalette.furDeep.opacity(0.25))
                        .frame(width: 20, height: 28)
                        .offset(x: -22, y: 15)
                    Ellipse()
                        .fill(LumaPalette.furDeep.opacity(0.25))
                        .frame(width: 20, height: 28)
                        .offset(x: 22, y: 15)
                    Ellipse()
                        .fill(LumaPalette.cream.opacity(0.95))
                        .frame(width: 32, height: 40)
                        .offset(y: 11)
                }
            }
            .clipShape(LumaBunnyBodyShape())
            .offset(x: 1)
            .scaleEffect(
                x: 1,
                y: pose.torsoSquash + 0.014 * pose.breath,
                anchor: .bottom
            )
    }

    /// Tiny raised front paws held at the chest.
    private var paws: some View {
        HStack(spacing: 5) {
            pawDot(rotation: -16)
            pawDot(rotation: 16)
        }
        .offset(x: 1, y: -22 + CGFloat(-pose.breath * 0.8))
    }

    private func pawDot(rotation: Double) -> some View {
        Ellipse()
            .fill(LumaPalette.furLight)
            .overlay {
                Ellipse()
                    .strokeBorder(LumaPalette.furDeep.opacity(0.35), lineWidth: 1)
            }
            .frame(width: 11, height: 13)
            .rotationEffect(.degrees(rotation))
    }

    private var scarf: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(LumaPalette.scarfDeep)
                .frame(width: 36, height: 9)
                .offset(y: -40)
            FennFoxBandanaShape()
                .fill(
                    LinearGradient(
                        colors: [LumaPalette.scarf, LumaPalette.scarfDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 27, height: 22)
                .overlay {
                    LeafShape()
                        .fill(LumaPalette.cream.opacity(0.35))
                        .frame(width: 6, height: 10)
                        .rotationEffect(.degrees(20))
                        .offset(y: -2)
                }
                .offset(x: 4, y: -22)
        }
        .offset(x: 1)
    }

    // MARK: Head

    private var headGroup: some View {
        ZStack(alignment: .bottom) {
            // Slight asymmetry: left ear a touch longer and more upright.
            ear(side: -1, length: 45, baseAngle: -7, sway: pose.earSway(side: -1), flick: pose.earFlickLeft)
                .offset(x: -13, y: -44)
            ear(side: 1, length: 42, baseAngle: 6, sway: pose.earSway(side: 1), flick: pose.earFlickRight)
                .offset(x: 13, y: -44)
            headShape
            faceView
        }
        .frame(width: 92, height: 100, alignment: .bottom)
        .rotationEffect(.degrees(pose.headTilt), anchor: UnitPoint(x: 0.5, y: 0.85))
        .offset(x: 1, y: -36 + pose.headLiftY)
    }

    private func ear(side: Double, length: CGFloat, baseAngle: Double, sway: Double, flick: Double) -> some View {
        let angle = baseAngle + side * pose.earDroop + sway + flick
        return LumaBunnyEarShape()
            .fill(
                LinearGradient(
                    colors: [LumaPalette.furLight, LumaPalette.fur],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 17, height: length)
            .overlay {
                LumaBunnyEarShape()
                    .fill(LumaPalette.earInner.opacity(0.9))
                    .frame(width: 8, height: length * 0.62)
                    .offset(y: -length * 0.10)
            }
            .rotationEffect(.degrees(angle), anchor: .bottom)
    }

    private var headShape: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [LumaPalette.furLight, LumaPalette.fur],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
            )
            .frame(width: 58, height: 52)
            .overlay {
                Ellipse()
                    .fill(LumaPalette.cream.opacity(0.92))
                    .frame(width: 26, height: 19)
                    .offset(y: 14)
            }
            .clipShape(Ellipse())
    }

    private var faceView: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 20) {
                eye
                eye
            }
            .offset(x: pose.eyeDrift, y: -22)

            FennFoxNoseShape()
                .fill(LumaPalette.pawNose)
                .frame(width: 7, height: 5)
                .rotationEffect(.degrees(pose.noseTwitch * 8))
                .offset(x: CGFloat(pose.noseTwitch) * 0.8, y: -17)

            FennFoxMouthShape(lift: -0.5 + pose.smile * 2.2)
                .stroke(
                    LumaPalette.pawNose.opacity(0.75),
                    style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                )
                .frame(width: 14, height: 7)
                .offset(y: -11)

            HStack(spacing: 40) {
                blushDot
                blushDot
            }
            .offset(y: -15)
        }
    }

    @ViewBuilder private var eye: some View {
        if pose.showsHappyArcs {
            FennHappyEyeShape()
                .stroke(LumaPalette.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 9, height: 5)
                .padding(.vertical, 3)
        } else {
            ZStack {
                Ellipse()
                    .fill(LumaPalette.ink)
                Circle()
                    .fill(.white.opacity(0.92))
                    .frame(width: 2.8)
                    .offset(x: -1.6, y: -2.4)
                Circle()
                    .fill(.white.opacity(0.70))
                    .frame(width: 1.5)
                    .offset(x: 1.8, y: 2.2)
            }
            .frame(width: 9, height: 11)
            .scaleEffect(x: 1, y: max(0.12, pose.eyeOpenness), anchor: .center)
        }
    }

    private var blushDot: some View {
        Ellipse()
            .fill(LumaPalette.blushPink.opacity(pose.blushOpacity))
            .frame(width: 9, height: 5.5)
    }

    // MARK: Emotes

    @ViewBuilder private var emotes: some View {
        if pose.sparkleStrength > 0.04 {
            sparkle(size: 9, x: -44, y: -100, phase: 0)
            sparkle(size: 7, x: 42, y: -88, phase: 2.1)
            sparkle(size: 6, x: -36, y: -32, phase: 4.2)
        }
        if pose.isPetting {
            heart(x: -32, y: -92, seed: 0)
            heart(x: 36, y: -98, seed: 0.55)
        }
        if pose.state == .tired && !pose.isPetting {
            snore(x: 40, y: -100, size: 10, seed: 0)
            snore(x: 49, y: -110, size: 13, seed: 0.5)
        }
    }

    private func sparkle(size: CGFloat, x: CGFloat, y: CGFloat, phase: Double) -> some View {
        let twinkle = (sin(pose.time * 2.4 + phase) + 1) / 2
        return FennSparkleShape()
            .fill(LumaPalette.sparkle)
            .frame(width: size, height: size)
            .scaleEffect(0.7 + twinkle * 0.5 + pose.excitement * 0.4)
            .opacity(pose.sparkleStrength * (0.35 + twinkle * 0.65))
            .offset(x: x, y: y)
    }

    private func heart(x: CGFloat, y: CGFloat, seed: Double) -> some View {
        let phase = (pose.time * 0.7 + seed).truncatingRemainder(dividingBy: 1)
        return Image(systemName: "heart.fill")
            .font(.system(size: 9))
            .foregroundStyle(LumaPalette.blushPink.opacity((1 - phase) * 0.9))
            .scaleEffect(0.7 + phase * 0.5)
            .offset(x: x + sin(phase * 2 * .pi) * 3, y: y - phase * 20)
    }

    private func snore(x: CGFloat, y: CGFloat, size: CGFloat, seed: Double) -> some View {
        let phase = (pose.time * 0.4 + seed).truncatingRemainder(dividingBy: 1)
        return Text("z")
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(LumaPalette.furDeep.opacity((1 - phase) * 0.65))
            .offset(x: x + phase * 5, y: y - phase * 14)
    }
}

// MARK: - Shapes

/// Squat rounded pear: wider at the haunches, soft at the shoulders.
struct LumaBunnyBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.72),
            control1: CGPoint(x: w * 0.86, y: h * 0.04),
            control2: CGPoint(x: w, y: h * 0.38)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.76, y: h),
            control1: CGPoint(x: w, y: h * 0.90),
            control2: CGPoint(x: w * 0.90, y: h)
        )
        p.addLine(to: CGPoint(x: w * 0.24, y: h))
        p.addCurve(
            to: CGPoint(x: 0, y: h * 0.72),
            control1: CGPoint(x: w * 0.10, y: h),
            control2: CGPoint(x: 0, y: h * 0.90)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: 0, y: h * 0.38),
            control2: CGPoint(x: w * 0.14, y: h * 0.04)
        )
        p.closeSubpath()
        return p
    }
}

/// Long soft ear: rounded tip, gently tapered base.
struct LumaBunnyEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.02))
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.30),
            control1: CGPoint(x: w * 0.80, y: h * 0.02),
            control2: CGPoint(x: w, y: h * 0.14)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.96),
            control1: CGPoint(x: w, y: h * 0.60),
            control2: CGPoint(x: w * 0.92, y: h * 0.85)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.96),
            control: CGPoint(x: w * 0.5, y: h * 1.04)
        )
        p.addCurve(
            to: CGPoint(x: 0, y: h * 0.30),
            control1: CGPoint(x: w * 0.08, y: h * 0.85),
            control2: CGPoint(x: 0, y: h * 0.60)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.02),
            control1: CGPoint(x: 0, y: h * 0.14),
            control2: CGPoint(x: w * 0.20, y: h * 0.02)
        )
        p.closeSubpath()
        return p
    }
}

#Preview("Luma states") {
    HStack(spacing: 24) {
        LumaBunnyView(state: .calm)
        LumaBunnyView(state: .happy)
        LumaBunnyView(state: .tired)
    }
    .padding(40)
    .background(Color(red: 0.98, green: 0.95, blue: 0.88))
}
