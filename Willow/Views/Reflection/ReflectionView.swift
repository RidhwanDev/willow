import SwiftData
import SwiftUI

struct ReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]

    @State private var selectedParentIndex = 0
    @State private var mood: ReflectionMood = .steady
    @State private var energyLabel = "Enough for small things"
    @State private var note = ""

    private let engine = WellbeingEngine()
    private let energyOptions = ["Running on empty", "A little stretched", "Enough for small things", "Mostly steady", "Rested and open"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WillowSpacing.large) {
                    SoftCard {
                        Text(engine.weeklySummary(moments: moments))
                            .font(.headline)
                            .foregroundStyle(WillowColors.ink)
                            .lineSpacing(4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling this week?")
                            .font(.title2.bold())
                            .foregroundStyle(WillowColors.ink)

                        Picker("Parent", selection: $selectedParentIndex) {
                            ForEach(parents.indices, id: \.self) { index in
                                Text(parents[index].name).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                            ForEach(ReflectionMood.allCases) { option in
                                moodButton(option)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Did you get enough time for yourself?")
                            .font(.headline)
                            .foregroundStyle(WillowColors.ink)

                        Picker("Energy", selection: $energyLabel) {
                            ForEach(energyOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .padding(16)
                    .background(WillowColors.softCream.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What would help next week?")
                            .font(.headline)
                            .foregroundStyle(WillowColors.ink)

                        TextField("A little protected time, a walk, a slow morning...", text: $note, axis: .vertical)
                            .lineLimit(4...7)
                            .padding(14)
                            .background(WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    PrimaryButton(title: "Save Reflection", systemImage: "leaf.arrow.circlepath", action: save)

                    if !reflections.isEmpty {
                        recentReflections
                    }
                }
                .padding(WillowSpacing.large)
            }
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Reflection")
        }
    }

    private func moodButton(_ option: ReflectionMood) -> some View {
        Button {
            mood = option
        } label: {
            VStack(spacing: 8) {
                Image(systemName: option.symbolName)
                    .font(.title2)
                Text(option.title)
                    .font(.subheadline.weight(.semibold))
                    .minimumScaleFactor(0.86)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(mood == option ? WillowColors.deepLeaf : WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(mood == option ? .white : WillowColors.ink)
        }
        .buttonStyle(.plain)
    }

    private var recentReflections: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent reflections")
                .font(.title2.bold())
                .foregroundStyle(WillowColors.ink)

            ForEach(reflections.prefix(3)) { reflection in
                HStack(spacing: 12) {
                    Image(systemName: reflection.mood.symbolName)
                        .foregroundStyle(WillowColors.leaf)
                        .frame(width: 34, height: 34)
                        .background(WillowColors.softCream, in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(name(for: reflection.parentId)) felt \(reflection.mood.title.lowercased())")
                            .font(.headline)
                            .foregroundStyle(WillowColors.ink)
                        if let note = reflection.note, !note.isEmpty {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(WillowColors.muted)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(14)
                .background(WillowColors.softCream.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func save() {
        guard parents.indices.contains(selectedParentIndex) else { return }
        let reflection = WeeklyReflection(
            weekStartDate: startOfWeek(for: .now),
            parentId: parents[selectedParentIndex].id,
            mood: mood,
            energyLevel: energyLevel,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        )
        modelContext.insert(reflection)
        note = ""
    }

    private var energyLevel: Int {
        (energyOptions.firstIndex(of: energyLabel) ?? 2) + 1
    }

    private func startOfWeek(for date: Date) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? Calendar.current.startOfDay(for: date)
    }

    private func name(for id: UUID) -> String {
        parents.first { $0.id == id }?.name ?? "Parent"
    }
}
