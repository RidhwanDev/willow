import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]

    var body: some View {
        if parents.count >= 2 {
            RootTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Models

@Model
final class ParentProfile {
    var id: UUID
    var name: String
    var companionName: String
    var companionType: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, companionName: String, companionType: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.companionName = companionName
        self.companionType = companionType
        self.createdAt = createdAt
    }
}

@Model
final class WellbeingMoment {
    var id: UUID
    var parentId: UUID
    var type: MomentType
    var title: String
    var date: Date
    var durationMinutes: Int
    var timeQuality: TimeQuality
    var notes: String?

    init(id: UUID = UUID(), parentId: UUID, type: MomentType, title: String, date: Date = .now, durationMinutes: Int, timeQuality: TimeQuality, notes: String? = nil) {
        self.id = id
        self.parentId = parentId
        self.type = type
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.timeQuality = timeQuality
        self.notes = notes
    }
}

@Model
final class ProtectedTimePlan {
    var id: UUID
    var parentId: UUID
    var protectedByParentId: UUID?
    var title: String
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), parentId: UUID, protectedByParentId: UUID? = nil, title: String, startDate: Date, endDate: Date, isCompleted: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.parentId = parentId
        self.protectedByParentId = protectedByParentId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

@Model
final class WeeklyReflection {
    var id: UUID
    var weekStartDate: Date
    var parentId: UUID
    var mood: ReflectionMood
    var energyLevel: Int
    var note: String?

    init(id: UUID = UUID(), weekStartDate: Date, parentId: UUID, mood: ReflectionMood, energyLevel: Int, note: String? = nil) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.parentId = parentId
        self.mood = mood
        self.energyLevel = min(max(energyLevel, 1), 5)
        self.note = note
    }
}

// MARK: - Enums

enum MomentType: String, Codable, CaseIterable, Identifiable {
    case exercise, friends, hobby, rest, learning, faithReflection, sideProject, coupleTime, familyTime, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .exercise: "Exercise"
        case .friends: "Friends"
        case .hobby: "Hobby"
        case .rest: "Rest"
        case .learning: "Learning"
        case .faithReflection: "Faith"
        case .sideProject: "Side project"
        case .coupleTime: "Couple time"
        case .familyTime: "Family time"
        case .other: "Other"
        }
    }
    var symbolName: String {
        switch self {
        case .exercise: "figure.run"
        case .friends: "cup.and.saucer.fill"
        case .hobby: "paintpalette.fill"
        case .rest: "moon.stars.fill"
        case .learning: "book.fill"
        case .faithReflection: "sparkles"
        case .sideProject: "hammer.fill"
        case .coupleTime: "heart.fill"
        case .familyTime: "figure.2.and.child.holdinghands"
        case .other: "leaf.fill"
        }
    }
}

enum TimeQuality: String, Codable, CaseIterable, Identifiable {
    case protectedTime, personalTime, passiveTime, sharedFamilyTime, coupleTime
    var id: String { rawValue }
    var title: String {
        switch self {
        case .protectedTime: "Protected"
        case .personalTime: "Personal"
        case .passiveTime: "Passive"
        case .sharedFamilyTime: "Family"
        case .coupleTime: "Couple"
        }
    }
    var explanation: String {
        switch self {
        case .protectedTime: "Someone else was fully responsible."
        case .personalTime: "You had time for yourself, but were still lightly on duty."
        case .passiveTime: "You had downtime, but it wasn't really restorative."
        case .sharedFamilyTime: "You spent meaningful time together."
        case .coupleTime: "You protected time for your relationship."
        }
    }
}

enum ParentState: String, Codable { case flourishing, steady, tired, needsCare }
enum FamilyTreeState: String, Codable { case flourishing, growing, steady, tired, needsCare }
enum ReflectionMood: String, Codable, CaseIterable, Identifiable {
    case flourishing, steady, tired, needsCare
    var id: String { rawValue }
    var title: String {
        switch self { case .flourishing: "Flourishing"; case .steady: "Steady"; case .tired: "Tired"; case .needsCare: "Need care" }
    }
    var symbolName: String {
        switch self { case .flourishing: "sun.max.fill"; case .steady: "leaf.fill"; case .tired: "cloud.sun.fill"; case .needsCare: "hands.sparkles.fill" }
    }
}

// MARK: - Theme

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
        LinearGradient(colors: [sky.opacity(0.68), cream, softCream], startPoint: .top, endPoint: .bottom)
    }
}

enum WillowSpacing { static let large: CGFloat = 22 }

// MARK: - Services

struct WellbeingEngine {
    private let calendar = Calendar.current

    func parentState(for parent: ParentProfile, moments: [WellbeingMoment], referenceDate: Date = .now) -> ParentState {
        if hasGoneWithoutCare(parent.id, moments: moments, referenceDate: referenceDate) { return .needsCare }
        let score = moments.filter { $0.parentId == parent.id && $0.date >= sevenDaysAgo(from: referenceDate) }.reduce(0.0) { $0 + points(for: $1.timeQuality, parentFocused: true) }
        switch score { case 8...: return .flourishing; case 5..<8: return .steady; case 2..<5: return .tired; default: return .needsCare }
    }

    func familyTreeState(for parents: [ParentProfile], moments: [WellbeingMoment], referenceDate: Date = .now) -> FamilyTreeState {
        let score = moments.filter { $0.date >= sevenDaysAgo(from: referenceDate) }.reduce(0.0) { $0 + points(for: $1.timeQuality, parentFocused: false) }
        switch score { case 12...: return .flourishing; case 8..<12: return .growing; case 5..<8: return .steady; case 2..<5: return .tired; default: return .needsCare }
    }

    func nudge(for parents: [ParentProfile], moments: [WellbeingMoment]) -> String {
        for parent in parents where hasGoneWithoutCare(parent.id, moments: moments, referenceDate: .now) {
            return "\(parent.name) may need protected time soon. Could you reserve a little space this week?"
        }
        return moments.contains { $0.timeQuality == .coupleTime && $0.date >= sevenDaysAgo(from: .now) } ? "You both shared a lovely moment this week. Keep protecting the little spaces that help you feel like yourselves." : "A small protected moment together could help your willow feel more rooted."
    }

    func statusText(for state: FamilyTreeState) -> String {
        switch state {
        case .flourishing: "Your family has had rich, restorative moments this week. The willow feels bright and alive."
        case .growing: "Your family has had some good moments this week. A little protected time would help it thrive."
        case .steady: "There is care here. A few intentional pockets of rest could help the willow grow stronger."
        case .tired: "Your willow could use some care. A gentle plan for protected time may help soon."
        case .needsCare: "Your willow is asking for care. Start with one small moment that gives someone real breathing room."
        }
    }

    func weeklySummary(moments: [WellbeingMoment]) -> String {
        let recent = moments.filter { $0.date >= sevenDaysAgo(from: .now) }
        let recharge = recent.filter { $0.timeQuality == .protectedTime || $0.timeQuality == .personalTime }.count
        let protected = recent.filter { $0.timeQuality == .protectedTime }.count
        let couple = recent.filter { $0.timeQuality == .coupleTime }.count
        return "This week, your family shared \(recharge) recharge moments, \(protected) protected time block\(protected == 1 ? "" : "s"), and \(couple) couple moment\(couple == 1 ? "" : "s")."
    }

    private func hasGoneWithoutCare(_ parentId: UUID, moments: [WellbeingMoment], referenceDate: Date) -> Bool {
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: referenceDate) ?? referenceDate
        return moments.filter { $0.parentId == parentId && $0.date >= fiveDaysAgo && ($0.timeQuality == .protectedTime || $0.timeQuality == .personalTime) }.isEmpty
    }

    private func sevenDaysAgo(from date: Date) -> Date { calendar.date(byAdding: .day, value: -7, to: date) ?? date }
    private func points(for quality: TimeQuality, parentFocused: Bool) -> Double {
        switch quality { case .protectedTime: 3; case .personalTime: 2; case .passiveTime: 0.5; case .sharedFamilyTime: parentFocused ? 0 : 2; case .coupleTime: parentFocused ? 0 : 3 }
    }
}

struct SampleDataService {
    @MainActor static func seedIfNeeded(modelContext: ModelContext, parents: [ParentProfile]) {
        guard parents.isEmpty else { return }
        let ridhwan = ParentProfile(name: "Ridhwan", companionName: "Fenn", companionType: "Fox")
        let anab = ParentProfile(name: "Anab", companionName: "Luma", companionType: "Rabbit")
        modelContext.insert(ridhwan); modelContext.insert(anab)
        let moments = [
            WellbeingMoment(parentId: ridhwan.id, type: .exercise, title: "Gym", date: daysAgo(1), durationMinutes: 60, timeQuality: .protectedTime),
            WellbeingMoment(parentId: anab.id, type: .friends, title: "Coffee with friends", date: daysAgo(2), durationMinutes: 90, timeQuality: .protectedTime),
            WellbeingMoment(parentId: ridhwan.id, type: .sideProject, title: "Built AkhiNet", date: daysAgo(3), durationMinutes: 120, timeQuality: .personalTime),
            WellbeingMoment(parentId: anab.id, type: .familyTime, title: "Family walk", date: daysAgo(4), durationMinutes: 60, timeQuality: .sharedFamilyTime),
            WellbeingMoment(parentId: anab.id, type: .coupleTime, title: "Date night", date: daysAgo(5), durationMinutes: 120, timeQuality: .coupleTime)
        ]
        moments.forEach(modelContext.insert)
    }
    private static func daysAgo(_ days: Int) -> Date { Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now }
}

// MARK: - Navigation

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "tree.fill") }
            MomentsView().tabItem { Label("Moments", systemImage: "sparkles") }
            ProtectView().tabItem { Label("Protect", systemImage: "shield.lefthalf.filled") }
            ReflectionView().tabItem { Label("Reflection", systemImage: "leaf.arrow.circlepath") }
        }
        .tint(WillowColors.deepLeaf)
    }
}

// MARK: - Components

struct SoftCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content.padding(WillowSpacing.large).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24)).shadow(color: WillowColors.deepLeaf.opacity(0.1), radius: 18, y: 10) }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @State private var trigger = false
    var body: some View {
        Button { trigger.toggle(); action() } label: {
            Label(title, systemImage: systemImage).font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(colors: [WillowColors.deepLeaf, WillowColors.leaf], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain).sensoryFeedback(.selection, trigger: trigger)
    }
}

struct NudgeCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "hands.sparkles.fill").foregroundStyle(WillowColors.amber).frame(width: 34, height: 34).background(WillowColors.amber.opacity(0.16), in: Circle())
            Text(text).font(.subheadline).foregroundStyle(WillowColors.ink).lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(18).background(WillowColors.softCream.opacity(0.86), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct MomentCard: View {
    let moment: WellbeingMoment
    let parentName: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: moment.type.symbolName).foregroundStyle(WillowColors.deepLeaf).frame(width: 44, height: 44).background(WillowColors.leaf.opacity(0.16), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(moment.title).font(.headline).foregroundStyle(WillowColors.ink)
                Text("\(parentName) · \(moment.timeQuality.title) · \(moment.durationMinutes) min").font(.subheadline).foregroundStyle(WillowColors.muted)
            }
            Spacer()
        }.padding(16).background(WillowColors.softCream.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct CompanionView: View {
    let parent: ParentProfile
    let state: ParentState
    let delay: Double

    @State private var bounce = false
    @State private var breathe = false
    @State private var blink = false
    @State private var tailWag = false
    @State private var blinkTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 5) {
            if hasBespokeCharacter {
                mascot
                    .scaleEffect(0.66, anchor: .bottom)
                    .frame(width: 68, height: 72, alignment: .bottom)
                    .offset(y: -1)
                    .saturation(state == .needsCare ? 0.48 : 1)
            } else {
                mascot
                    .scaleEffect(breathe ? 0.76 : 0.73, anchor: .bottom)
                    .frame(width: 68, height: 72)
                    .offset(y: bounce ? -3 : 2)
                    .saturation(state == .needsCare ? 0.48 : 1)
                    .shadow(color: palette.shadow.opacity(0.24), radius: 10, x: 0, y: 7)
                    .animation(.easeInOut(duration: bounceDuration).repeatForever(autoreverses: true).delay(delay), value: bounce)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(delay * 0.5), value: breathe)
            }

        }
        .onAppear {
            bounce = !hasBespokeCharacter && state != .needsCare
            breathe = true
            tailWag = true
            if !hasBespokeCharacter {
                startBlinking()
            }
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
        }
    }

    private func startBlinking() {
        guard blinkTask == nil else { return }
        blinkTask = Task {
            try? await Task.sleep(nanoseconds: UInt64((2.7 + delay) * 1_000_000_000))

            while !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.08)) {
                        blink = true
                    }
                }

                try? await Task.sleep(nanoseconds: 130_000_000)

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.10)) {
                        blink = false
                    }
                }

                try? await Task.sleep(nanoseconds: UInt64(blinkPause * 1_000_000_000))
            }
        }
    }

    private var hasBespokeCharacter: Bool {
        species == .fox || species == .rabbit
    }

    @ViewBuilder private var mascot: some View {
        if species == .fox {
            FennFoxView(state: companionState)
        } else if species == .rabbit {
            LumaBunnyView(state: companionState)
        } else {
            ZStack(alignment: .bottom) {
                softAura
                tail
                mascotBody
                head
                face
                sparkle
            }
        }
    }

    private var softAura: some View {
        Circle()
            .fill(palette.primary.opacity(0.16))
            .frame(width: 74, height: 74)
            .blur(radius: 10)
            .offset(y: 11)
    }

    @ViewBuilder private var tail: some View {
        switch species {
        case .fox:
            MascotTailShape(curl: 0.12)
                .fill(LinearGradient(colors: [palette.primary, palette.secondary], startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 54, height: 62)
                .overlay(alignment: .topTrailing) {
                    MascotTailShape(curl: 0.12)
                        .trim(from: 0.70, to: 1)
                        .stroke(Color.white.opacity(0.80), lineWidth: 8)
                        .frame(width: 54, height: 62)
                }
                .rotationEffect(.degrees(tailWag ? -9 : -17), anchor: .bottomLeading)
                .offset(x: 28, y: -9)
                .animation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true).delay(delay), value: tailWag)
        case .rabbit:
            EmptyView()
        case .squirrel:
            MascotTailShape(curl: 0.55)
                .fill(LinearGradient(colors: [palette.secondary, palette.primary], startPoint: .bottom, endPoint: .top))
                .frame(width: 62, height: 78)
                .rotationEffect(.degrees(tailWag ? 16 : 7), anchor: .bottomLeading)
                .offset(x: 29, y: -16)
                .animation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true).delay(delay), value: tailWag)
        case .otter:
            Capsule()
                .fill(palette.secondary)
                .frame(width: 22, height: 56)
                .rotationEffect(.degrees(tailWag ? 47 : 36), anchor: .top)
                .offset(x: 31, y: 2)
                .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true).delay(delay), value: tailWag)
        }
    }

    private var mascotBody: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [palette.primary, palette.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 58)
            Capsule()
                .fill(Color.white.opacity(species == .otter ? 0.36 : 0.46))
                .frame(width: 28, height: 34)
                .offset(y: 9)
            HStack(spacing: 22) {
                paw
                paw
            }
            .offset(y: 29)
        }
        .offset(y: 4)
    }

    private var paw: some View {
        Capsule()
            .fill(palette.dark.opacity(0.78))
            .frame(width: 12, height: 8)
    }

    private var head: some View {
        ZStack {
            ears
            Circle()
                .fill(LinearGradient(colors: [palette.primary.lighter(0.12), palette.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 54, height: 54)
                .overlay(alignment: .bottom) {
                    muzzle
                }
        }
        .offset(y: -30)
    }

    @ViewBuilder private var ears: some View {
        switch species {
        case .fox:
            HStack(spacing: 20) {
                triangleEar(rotation: -20)
                triangleEar(rotation: 20)
            }
            .offset(y: -29)
        case .rabbit:
            HStack(spacing: 15) {
                longEar(rotation: -11)
                longEar(rotation: 13)
            }
            .offset(y: -42)
        case .squirrel:
            HStack(spacing: 25) {
                roundedEar
                roundedEar
            }
            .offset(y: -25)
        case .otter:
            HStack(spacing: 30) {
                roundedEar.frame(width: 15, height: 15)
                roundedEar.frame(width: 15, height: 15)
            }
            .offset(y: -18)
        }
    }

    private func triangleEar(rotation: Double) -> some View {
        MascotTriangle()
            .fill(palette.primary)
            .frame(width: 22, height: 28)
            .overlay {
                MascotTriangle()
                    .fill(Color.white.opacity(0.38))
                    .frame(width: 11, height: 14)
                    .offset(y: 4)
            }
            .rotationEffect(.degrees(rotation))
    }

    private func longEar(rotation: Double) -> some View {
        Capsule()
            .fill(palette.primary)
            .frame(width: 16, height: 46)
            .overlay {
                Capsule()
                    .fill(Color.white.opacity(0.42))
                    .frame(width: 8, height: 31)
            }
            .rotationEffect(.degrees(rotation), anchor: .bottom)
    }

    private var roundedEar: some View {
        Circle()
            .fill(palette.primary)
            .frame(width: 18, height: 18)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.34))
                    .frame(width: 9, height: 9)
            }
    }

    private var muzzle: some View {
        Ellipse()
            .fill(Color.white.opacity(species == .fox ? 0.74 : 0.58))
            .frame(width: species == .otter ? 34 : 31, height: 21)
            .offset(y: 5)
    }

    private var face: some View {
        ZStack {
            HStack(spacing: 17) {
                eye
                eye
            }
            .offset(y: -34)

            nose
                .offset(y: -25)

            mouth
                .offset(y: -18)

            HStack(spacing: 28) {
                blush
                blush
            }
            .offset(y: -23)

            if species == .otter {
                whiskers
                    .offset(y: -24)
            }
        }
    }

    private var eye: some View {
        Capsule()
            .fill(WillowColors.ink)
            .frame(width: 5.5, height: blink ? 2 : eyeHeight)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.white.opacity(blink ? 0 : 0.82))
                    .frame(width: 1.6, height: 1.6)
                    .offset(x: 1, y: 1)
            }
    }

    private var nose: some View {
        Circle()
            .fill(palette.dark)
            .frame(width: species == .otter ? 6 : 5, height: species == .otter ? 6 : 5)
    }

    private var mouth: some View {
        Capsule()
            .fill(WillowColors.ink.opacity(state == .needsCare ? 0.35 : 0.55))
            .frame(width: state == .needsCare ? 9 : 13, height: 2)
            .rotationEffect(.degrees(state == .tired || state == .needsCare ? 0 : -3))
    }

    private var blush: some View {
        Circle()
            .fill(Color(red: 0.95, green: 0.55, blue: 0.48).opacity(state == .needsCare ? 0.12 : 0.24))
            .frame(width: 8, height: 8)
    }

    private var whiskers: some View {
        VStack(spacing: 3) {
            whiskerRow(rotation: -6)
            whiskerRow(rotation: 6)
        }
    }

    private func whiskerRow(rotation: Double) -> some View {
        HStack(spacing: 18) {
            Capsule().frame(width: 14, height: 1)
            Capsule().frame(width: 14, height: 1)
        }
        .foregroundStyle(palette.dark.opacity(0.45))
        .rotationEffect(.degrees(rotation))
    }

    @ViewBuilder private var sparkle: some View {
        if state == .flourishing || state == .steady {
            Image(systemName: "sparkle")
                .font(.caption2.weight(.bold))
                .foregroundStyle(WillowColors.amber.opacity(0.9))
                .offset(x: -33, y: -57)
                .opacity(breathe ? 1 : 0.35)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(delay), value: breathe)
        }
    }

    private var species: CompanionSpecies {
        CompanionSpecies(rawValue: parent.companionType.lowercased()) ?? .fox
    }

    private var companionState: CompanionState {
        switch state {
        case .flourishing: .happy
        case .steady: .calm
        case .tired, .needsCare: .tired
        }
    }

    private var palette: MascotPalette {
        switch species {
        case .fox:
            MascotPalette(primary: WillowColors.amber, secondary: Color(red: 0.78, green: 0.38, blue: 0.20), dark: Color(red: 0.25, green: 0.13, blue: 0.09), shadow: WillowColors.amber)
        case .rabbit:
            MascotPalette(primary: Color(red: 0.78, green: 0.70, blue: 0.62), secondary: Color(red: 0.58, green: 0.50, blue: 0.45), dark: Color(red: 0.27, green: 0.22, blue: 0.20), shadow: Color(red: 0.58, green: 0.50, blue: 0.45))
        case .squirrel:
            MascotPalette(primary: Color(red: 0.62, green: 0.44, blue: 0.28), secondary: Color(red: 0.38, green: 0.25, blue: 0.17), dark: Color(red: 0.22, green: 0.13, blue: 0.09), shadow: Color(red: 0.46, green: 0.31, blue: 0.20))
        case .otter:
            MascotPalette(primary: Color(red: 0.46, green: 0.55, blue: 0.54), secondary: Color(red: 0.30, green: 0.40, blue: 0.42), dark: Color(red: 0.12, green: 0.19, blue: 0.20), shadow: Color(red: 0.30, green: 0.48, blue: 0.52))
        }
    }

    private var eyeHeight: CGFloat {
        switch state {
        case .flourishing: 8
        case .steady: 7
        case .tired: 5
        case .needsCare: 3
        }
    }

    private var blinkPause: Double {
        switch state {
        case .flourishing: 4.4
        case .steady: 5.2
        case .tired: 6.2
        case .needsCare: 7.0
        }
    }

    private var bounceDuration: Double {
        switch state {
        case .flourishing: 1.05
        case .steady: 1.55
        case .tired: 2.3
        case .needsCare: 3.8
        }
    }
}

enum CompanionSpecies: String {
    case fox, rabbit, squirrel, otter
}

struct MascotPalette {
    let primary: Color
    let secondary: Color
    let dark: Color
    let shadow: Color
}

struct MascotTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct MascotTailShape: Shape {
    let curl: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX * 0.80, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: rect.maxX * 0.76, y: rect.maxY * 0.92),
            control2: CGPoint(x: rect.maxX * (0.95 - curl * 0.20), y: rect.height * 0.32)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY * 0.55),
            control1: CGPoint(x: rect.maxX * (0.60 - curl * 0.16), y: rect.minY),
            control2: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.height * (0.25 + curl * 0.18))
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY),
            control1: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.maxY * 0.72),
            control2: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY * 0.94)
        )
        path.closeSubpath()
        return path
    }
}

private extension Color {
    func lighter(_ amount: Double) -> Color {
        mix(with: .white, by: amount)
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

// MARK: - Screens

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var step = 0
    @State private var parentOneName = "Ridhwan"
    @State private var parentTwoName = "Anab"
    @State private var parentOneCompanion = "Fox"
    @State private var parentTwoCompanion = "Rabbit"
    private let companionTypes = ["Fox", "Rabbit", "Squirrel", "Otter"]

    var body: some View {
        ZStack { WillowColors.backgroundGradient.ignoresSafeArea(); VStack(spacing: WillowSpacing.large) {
            Spacer(); WillowTreeView(state: .growing).frame(height: 280)
            Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center).foregroundStyle(WillowColors.ink)
            Text(message).font(.body).multilineTextAlignment(.center).foregroundStyle(WillowColors.muted).padding(.horizontal)
            content
            PrimaryButton(title: step == 3 ? "Enter Willow" : "Continue", systemImage: step == 3 ? "leaf.fill" : "arrow.right", action: advance).padding(.horizontal, WillowSpacing.large)
            if step < 2 { Button("Use demo family") { SampleDataService.seedIfNeeded(modelContext: modelContext, parents: parents) }.font(.subheadline.weight(.semibold)).foregroundStyle(WillowColors.deepLeaf) }
            Spacer()
        }}
    }
    @ViewBuilder private var content: some View {
        if step == 2 { VStack { TextField("Parent 1", text: $parentOneName); TextField("Parent 2", text: $parentTwoName) }.textFieldStyle(.roundedBorder).padding(.horizontal) }
        else if step == 3 { VStack { picker(parentOneName, $parentOneCompanion); picker(parentTwoName, $parentTwoCompanion) }.padding(.horizontal) }
        else if step == 1 { SoftCard { Text("Willow helps your family protect time to recharge, reconnect, and stay yourselves while raising children.").font(.headline).multilineTextAlignment(.center) }.padding(.horizontal) }
    }
    private func picker(_ title: String, _ selection: Binding<String>) -> some View { VStack(alignment: .leading) { Text(title).font(.headline); Picker(title, selection: selection) { ForEach(companionTypes, id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented) } }
    private var title: String { ["Meet Willow", "A living reminder", "Add your family", "Choose companions"][step] }
    private var message: String { ["A calm place to notice whether your family is getting the care it needs.", "Your family willow reflects protected time, rest, friendship, hobbies, couple time, and connection.", "Start with two parents or carers.", "Each parent has a small companion around the tree."][step] }
    private func advance() { step < 3 ? withAnimation { step += 1 } : createFamily() }
    private func createFamily() { modelContext.insert(ParentProfile(name: parentOneName, companionName: "Fenn", companionType: parentOneCompanion)); modelContext.insert(ParentProfile(name: parentTwoName, companionName: "Luma", companionType: parentTwoCompanion)) }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @Query(sort: \ProtectedTimePlan.startDate) private var plans: [ProtectedTimePlan]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]

    @State private var addMoment = false
    @State private var protect = false
    @State private var showingSettings = false
    @State private var confirmingReset = false
    @State private var season: WillowSeason = .current()
    @State private var dayPhase: WillowDayPhase = .current()

    private let engine = WellbeingEngine()

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: WillowSpacing.large) {
                        heroScene(
                            topInset: proxy.safeAreaInsets.top,
                            height: max(500, (proxy.size.height + proxy.safeAreaInsets.top) * 0.62)
                        )

                        Group {
                            actionRow
                            NudgeCard(text: engine.nudge(for: parents, moments: moments))
                            demoControls
                        }
                        .padding(.horizontal, WillowSpacing.large)
                    }
                    .padding(.bottom, WillowSpacing.large)
                }
                .scrollIndicators(.hidden)
                .background(WillowColors.backgroundGradient.ignoresSafeArea())
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $addMoment) { AddMomentSheet() }
        .sheet(isPresented: $protect) { AddProtectedTimeSheet() }
        .sheet(isPresented: $showingSettings) { demoSettingsSheet }
    }

    /// The scene owns the whole top of the page: sky flows up under the
    /// status bar, the header text floats on top of it, and the bottom
    /// edge dissolves into the app background.
    private func heroScene(topInset: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            WillowSceneView(season: season, phase: dayPhase) {
                ZStack(alignment: .bottom) {
                    WillowTreeView(state: treeState, season: season)
                    HStack {
                        if let first = parents.first {
                            CompanionView(parent: first, state: engine.parentState(for: first, moments: moments), delay: 0.1)
                        }
                        Spacer()
                        if parents.count > 1 {
                            CompanionView(parent: parents[1], state: engine.parentState(for: parents[1], moments: moments), delay: 0.65)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: -2)
                }
            }

            header
                .padding(.top, topInset + 8)
                .padding(.horizontal, WillowSpacing.large)
        }
        .frame(height: height)
        .sensoryFeedback(.selection, trigger: season)
        .sensoryFeedback(.selection, trigger: dayPhase)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Willow is \(treeTitle)")
                .font(.largeTitle.bold())
                .foregroundStyle(dayPhase == .night ? WillowColors.softCream : WillowColors.ink)
            Text(engine.statusText(for: treeState))
                .foregroundStyle(dayPhase == .night ? WillowColors.softCream.opacity(0.78) : WillowColors.muted)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.8), value: dayPhase)
    }

    /// Demo-only controls, tucked below the content so they never sit on
    /// top of the scene: season, day/night and settings.
    private var demoControls: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.8)) { season = season.next }
            } label: {
                Image(systemName: season.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WillowColors.deepLeaf)
                    .frame(width: 36, height: 36)
                    .background(WillowColors.softCream.opacity(0.82), in: Circle())
            }
            .accessibilityLabel("Season: \(season.title). Tap to change season")

            Button {
                withAnimation(.easeInOut(duration: 0.8)) { dayPhase = dayPhase.toggled }
            } label: {
                Image(systemName: dayPhase == .day ? "moon.fill" : "sun.max.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WillowColors.deepLeaf)
                    .frame(width: 36, height: 36)
                    .background(WillowColors.softCream.opacity(0.82), in: Circle())
            }
            .accessibilityLabel(dayPhase == .day ? "Switch to night" : "Switch to day")

            Button {
                showingSettings = true
            } label: {
                Label("Demo settings", systemImage: "gearshape.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(WillowColors.muted)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(WillowColors.softCream.opacity(0.82), in: Capsule())
            }
            .accessibilityLabel("Demo settings")
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var actionRow: some View {
        HStack {
            Button {
                addMoment = true
            } label: {
                Label("Add Moment", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(WillowColors.deepLeaf, in: RoundedRectangle(cornerRadius: 18))
                    .foregroundStyle(.white)
            }

            Button {
                protect = true
            } label: {
                Label("Protect Time", systemImage: "shield.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(WillowColors.amber.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
                    .foregroundStyle(WillowColors.ink)
            }
        }
        .buttonStyle(.plain)
    }

    private var demoSettingsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: WillowSpacing.large) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Demo testing")
                            .font(.title2.bold())
                            .foregroundStyle(WillowColors.ink)
                        Text("Return to the main menu when you need to test onboarding again. This clears local demo data only.")
                            .foregroundStyle(WillowColors.muted)
                            .lineSpacing(4)
                    }
                }

                Button(role: .destructive) {
                    confirmingReset = true
                } label: {
                    Label("Return to Main Menu", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.82))

                Spacer()
            }
            .padding(WillowSpacing.large)
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingSettings = false }
                }
            }
            .confirmationDialog("Return to main menu?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Clear Demo Data", role: .destructive) {
                    resetToMainMenu()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes parents, moments, protected time, and reflections stored on this device.")
            }
        }
    }

    private func resetToMainMenu() {
        moments.forEach(modelContext.delete)
        plans.forEach(modelContext.delete)
        reflections.forEach(modelContext.delete)
        parents.forEach(modelContext.delete)
        showingSettings = false
    }

    private var treeState: FamilyTreeState { engine.familyTreeState(for: parents, moments: moments) }
    private var treeTitle: String { switch treeState { case .flourishing: "flourishing"; case .growing: "growing"; case .steady: "steady"; case .tired: "a little tired"; case .needsCare: "asking for care" } }
}

struct MomentsView: View {
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var showingAdd = false
    var body: some View { NavigationStack { ZStack(alignment: .bottomTrailing) { ScrollView { LazyVStack(alignment: .leading, spacing: 14) { if moments.isEmpty { SoftCard { Text("Small moments matter. Add something you did to recharge.").font(.headline).multilineTextAlignment(.center) } } else { ForEach(moments) { MomentCard(moment: $0, parentName: name(for: $0.parentId)) } } }.padding(WillowSpacing.large).padding(.bottom, 90) }; Button { showingAdd = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white).frame(width: 58, height: 58).background(WillowColors.deepLeaf, in: Circle()) }.padding(WillowSpacing.large) }.background(WillowColors.backgroundGradient.ignoresSafeArea()).navigationTitle("Moments") }.sheet(isPresented: $showingAdd) { AddMomentSheet() } }
    private func name(for id: UUID) -> String { parents.first { $0.id == id }?.name ?? "Parent" }
}

struct AddMomentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var parentIndex = 0
    @State private var type: MomentType = .rest
    @State private var title = ""
    @State private var date = Date()
    @State private var duration = 30
    @State private var quality: TimeQuality = .protectedTime
    @State private var notes = ""
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: WillowSpacing.large) { Picker("Parent", selection: $parentIndex) { ForEach(parents.indices, id: \.self) { Text(parents[$0].name).tag($0) } }.pickerStyle(.segmented); TextField("Gym, coffee, rest, date night...", text: $title).padding().background(WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18)); LazyVGrid(columns: [GridItem(.adaptive(minimum: 128))]) { ForEach(MomentType.allCases) { item in Button { type = item } label: { Label(item.title, systemImage: item.symbolName).font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12).background(type == item ? WillowColors.deepLeaf : WillowColors.softCream, in: Capsule()).foregroundStyle(type == item ? .white : WillowColors.ink) } } }; VStack(alignment: .leading) { ForEach(TimeQuality.allCases) { item in Button { quality = item } label: { HStack { Image(systemName: quality == item ? "checkmark.circle.fill" : "circle"); VStack(alignment: .leading) { Text(item.title).font(.headline); Text(item.explanation).font(.caption).foregroundStyle(WillowColors.muted) }; Spacer() }.padding().background(WillowColors.softCream.opacity(0.9), in: RoundedRectangle(cornerRadius: 18)).foregroundStyle(WillowColors.ink) } } }; DatePicker("When", selection: $date); Stepper("Duration: \(duration) minutes", value: $duration, in: 5...300, step: 5); TextField("Notes optional", text: $notes, axis: .vertical); PrimaryButton(title: "Add to Willow", systemImage: "leaf.fill", action: save) }.padding(WillowSpacing.large) }.background(WillowColors.backgroundGradient.ignoresSafeArea()).navigationTitle("Add Moment").toolbar { Button("Done") { dismiss() } } } }
    private func save() { guard parents.indices.contains(parentIndex) else { return }; modelContext.insert(WellbeingMoment(parentId: parents[parentIndex].id, type: type, title: title.isEmpty ? type.title : title, date: date, durationMinutes: duration, timeQuality: quality, notes: notes.isEmpty ? nil : notes)); dismiss() }
}

struct ProtectView: View {
    @Query(sort: \ProtectedTimePlan.startDate) private var plans: [ProtectedTimePlan]
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var showingAdd = false
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: WillowSpacing.large) { SoftCard { Text("Protected time means you are genuinely off-duty. No baby monitor, no half-listening, no waiting for the next wake-up.").font(.headline).lineSpacing(4) }; PrimaryButton(title: "Add Protected Time", systemImage: "plus.circle.fill") { showingAdd = true }; Text("Upcoming").font(.title2.bold()); ForEach(plans.filter { !$0.isCompleted }) { planCard($0) }; Text("Completed").font(.title2.bold()); ForEach(plans.filter { $0.isCompleted }) { planCard($0) } }.padding(WillowSpacing.large) }.background(WillowColors.backgroundGradient.ignoresSafeArea()).navigationTitle("Protect") }.sheet(isPresented: $showingAdd) { AddProtectedTimeSheet() } }
    private func planCard(_ plan: ProtectedTimePlan) -> some View { HStack { Image(systemName: plan.isCompleted ? "checkmark.seal.fill" : "shield.fill").foregroundStyle(WillowColors.amber); VStack(alignment: .leading) { Text("\(plan.startDate.formatted(.dateTime.weekday().hour().minute()))-\(plan.endDate.formatted(.dateTime.hour().minute()))").font(.subheadline.bold()).foregroundStyle(WillowColors.deepLeaf); Text("\(name(for: plan.parentId)): \(plan.title)").font(.headline); if let id = plan.protectedByParentId { Text("Protected by: \(name(for: id))").font(.subheadline).foregroundStyle(WillowColors.muted) } }; Spacer(); if !plan.isCompleted { Button { plan.isCompleted = true } label: { Image(systemName: "checkmark").foregroundStyle(.white).padding(10).background(WillowColors.deepLeaf, in: Circle()) } } }.padding().background(WillowColors.softCream.opacity(0.88), in: RoundedRectangle(cornerRadius: 22)) }
    private func name(for id: UUID) -> String { parents.first { $0.id == id }?.name ?? "Parent" }
}

struct AddProtectedTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var parentIndex = 0
    @State private var protectorIndex = 1
    @State private var title = ""
    @State private var start = Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now
    @State private var end = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
    var body: some View { NavigationStack { ScrollView { VStack(spacing: WillowSpacing.large) { Picker("Who is this for?", selection: $parentIndex) { ForEach(parents.indices, id: \.self) { Text(parents[$0].name).tag($0) } }.pickerStyle(.segmented); TextField("What will they do?", text: $title).padding().background(WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18)); DatePicker("Start time", selection: $start); DatePicker("End time", selection: $end); Picker("Protected by", selection: $protectorIndex) { ForEach(parents.indices, id: \.self) { Text(parents[$0].name).tag($0) } }.pickerStyle(.segmented); PrimaryButton(title: "Save Protected Time", systemImage: "shield.fill", action: save) }.padding(WillowSpacing.large) }.background(WillowColors.backgroundGradient.ignoresSafeArea()).navigationTitle("Protect Time").toolbar { Button("Done") { dismiss() } } } }
    private func save() { guard parents.indices.contains(parentIndex) else { return }; modelContext.insert(ProtectedTimePlan(parentId: parents[parentIndex].id, protectedByParentId: parents.indices.contains(protectorIndex) ? parents[protectorIndex].id : nil, title: title.isEmpty ? "Protected time" : title, startDate: start, endDate: max(end, start.addingTimeInterval(1800)))); dismiss() }
}

struct ReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]
    @State private var parentIndex = 0
    @State private var mood: ReflectionMood = .steady
    @State private var energy = "Enough for small things"
    @State private var note = ""
    private let energyOptions = ["Running on empty", "A little stretched", "Enough for small things", "Mostly steady", "Rested and open"]
    private let engine = WellbeingEngine()
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: WillowSpacing.large) { SoftCard { Text(engine.weeklySummary(moments: moments)).font(.headline).lineSpacing(4) }; Text("How are you feeling this week?").font(.title2.bold()); Picker("Parent", selection: $parentIndex) { ForEach(parents.indices, id: \.self) { Text(parents[$0].name).tag($0) } }.pickerStyle(.segmented); LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))]) { ForEach(ReflectionMood.allCases) { option in Button { mood = option } label: { VStack { Image(systemName: option.symbolName); Text(option.title).font(.subheadline.bold()) }.frame(maxWidth: .infinity).padding().background(mood == option ? WillowColors.deepLeaf : WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18)).foregroundStyle(mood == option ? .white : WillowColors.ink) } } }; Text("Did you get enough time for yourself?").font(.headline); Picker("Energy", selection: $energy) { ForEach(energyOptions, id: \.self) { Text($0).tag($0) } }.pickerStyle(.wheel).frame(height: 120); Text("What would help next week?").font(.headline); TextField("A little protected time, a walk, a slow morning...", text: $note, axis: .vertical).lineLimit(4...7).padding().background(WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18)); PrimaryButton(title: "Save Reflection", systemImage: "leaf.arrow.circlepath", action: save); ForEach(reflections.prefix(3)) { reflection in Text("\(name(for: reflection.parentId)) felt \(reflection.mood.title.lowercased())").padding().background(WillowColors.softCream.opacity(0.82), in: RoundedRectangle(cornerRadius: 18)) } }.padding(WillowSpacing.large) }.background(WillowColors.backgroundGradient.ignoresSafeArea()).navigationTitle("Reflection") } }
    private func save() { guard parents.indices.contains(parentIndex) else { return }; modelContext.insert(WeeklyReflection(weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now, parentId: parents[parentIndex].id, mood: mood, energyLevel: (energyOptions.firstIndex(of: energy) ?? 2) + 1, note: note.isEmpty ? nil : note)); note = "" }
    private func name(for id: UUID) -> String { parents.first { $0.id == id }?.name ?? "Parent" }
}

#Preview {
    ContentView()
        .modelContainer(for: [ParentProfile.self, WellbeingMoment.self, ProtectedTimePlan.self, WeeklyReflection.self], inMemory: true)
}
