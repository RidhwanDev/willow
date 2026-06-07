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
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(bodyColor.gradient).frame(width: 54, height: 54).saturation(state == .needsCare ? 0.45 : 1)
                HStack(spacing: 10) { Circle().frame(width: 5, height: 7); Circle().frame(width: 5, height: 7) }.foregroundStyle(WillowColors.ink).offset(y: -4)
                Capsule().fill(.white.opacity(0.52)).frame(width: 26, height: 12).offset(y: 24)
            }.overlay(alignment: .topTrailing) { Image(systemName: symbolName).font(.caption).foregroundStyle(.white).padding(5).background(WillowColors.deepLeaf.opacity(0.82), in: Circle()).offset(x: 5, y: -5) }
            .offset(y: bounce ? -5 : 3).animation(.easeInOut(duration: state == .flourishing ? 1.15 : 1.8).repeatForever(autoreverses: true).delay(delay), value: bounce)
            Text(parent.companionName).font(.caption.weight(.semibold)).foregroundStyle(WillowColors.deepLeaf)
        }.onAppear { bounce = state != .needsCare }
    }
    private var symbolName: String { parent.companionType == "Rabbit" ? "hare.fill" : "pawprint.fill" }
    private var bodyColor: Color { parent.companionType == "Rabbit" ? Color(red: 0.78, green: 0.69, blue: 0.60) : WillowColors.amber }
}

struct WillowTreeView: View {
    let state: FamilyTreeState
    @State private var sway = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            glow
            trunk
                .rotationEffect(.degrees(sway ? 2 : -2), anchor: .bottom)
            canopy
                .offset(y: state == .needsCare ? 12 : 0)
                .rotationEffect(.degrees(sway ? -2 : 2), anchor: .bottom)
        }
        .frame(height: 330)
        .onAppear {
            sway = true
            pulse = true
        }
        .animation(.easeInOut(duration: state == .needsCare ? 5.5 : 3.2).repeatForever(autoreverses: true), value: sway)
    }

    private var glow: some View {
        Circle()
            .fill(glowColor.opacity(pulse ? 0.32 : 0.15))
            .frame(width: 250, height: 250)
            .blur(radius: 28)
            .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)
    }

    private var trunk: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(WillowColors.bark)
                .frame(width: 34, height: 178)
                .offset(y: 58)
            branch(angle: -35, x: -35)
            branch(angle: 32, x: 34)
            branch(angle: -16, x: -13)
            branch(angle: 18, x: 16)
        }
    }

    private func branch(angle: Double, x: CGFloat) -> some View {
        Capsule()
            .fill(WillowColors.bark.opacity(0.82))
            .frame(width: 10, height: 88)
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .offset(x: x, y: -12)
    }

    private var canopy: some View {
        ZStack {
            ForEach(0..<28, id: \.self) { index in
                leaf(index: index)
            }
        }
        .saturation(state == .needsCare ? 0.55 : 1)
    }

    private func leaf(index: Int) -> some View {
        let size = leafSize(index)
        let offset = leafOffset(index)

        return LeafShape()
            .fill(leafColor.gradient)
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(Double(index * 23)))
            .offset(x: offset.x, y: offset.y)
            .opacity(state == .needsCare ? 0.72 : 0.96)
    }

    private func leafSize(_ index: Int) -> CGSize {
        CGSize(width: CGFloat(34 + (index % 4) * 4), height: CGFloat(64 + (index % 3) * 8))
    }

    private func leafOffset(_ index: Int) -> CGPoint {
        let column = index % 7
        let row = index / 7
        return CGPoint(x: CGFloat(column * 35 - 105), y: CGFloat(row * 42 - 112 + abs(column - 3) * 7))
    }

    private var leafColor: Color {
        state == .needsCare ? WillowColors.muted : (state == .flourishing ? WillowColors.leaf : WillowColors.moss)
    }

    private var glowColor: Color {
        state == .flourishing ? WillowColors.amber : WillowColors.leaf
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path { var path = Path(); path.move(to: CGPoint(x: rect.midX, y: rect.minY)); path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY)); path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY)); return path }
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
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @State private var addMoment = false
    @State private var protect = false
    private let engine = WellbeingEngine()
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing: WillowSpacing.large) {
            VStack(alignment: .leading, spacing: 8) { Text("Your Willow is \(treeTitle)").font(.largeTitle.bold()).foregroundStyle(WillowColors.ink); Text(engine.statusText(for: treeState)).foregroundStyle(WillowColors.muted).lineSpacing(4) }
            ZStack(alignment: .bottom) { WillowTreeView(state: treeState); HStack { if let first = parents.first { CompanionView(parent: first, state: engine.parentState(for: first, moments: moments), delay: 0.1) }; Spacer(); if parents.count > 1 { CompanionView(parent: parents[1], state: engine.parentState(for: parents[1], moments: moments), delay: 0.65) } }.padding(.horizontal, 24) }.frame(height: 380)
            HStack { Button { addMoment = true } label: { Label("Add Moment", systemImage: "plus.circle.fill").frame(maxWidth: .infinity).padding().background(WillowColors.deepLeaf, in: RoundedRectangle(cornerRadius: 18)).foregroundStyle(.white) }; Button { protect = true } label: { Label("Protect Time", systemImage: "shield.fill").frame(maxWidth: .infinity).padding().background(WillowColors.amber.opacity(0.22), in: RoundedRectangle(cornerRadius: 18)).foregroundStyle(WillowColors.ink) } }
            NudgeCard(text: engine.nudge(for: parents, moments: moments))
        }.padding(WillowSpacing.large) }.background(WillowColors.backgroundGradient.ignoresSafeArea()).navigationBarHidden(true) }.sheet(isPresented: $addMoment) { AddMomentSheet() }.sheet(isPresented: $protect) { AddProtectedTimeSheet() }
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
