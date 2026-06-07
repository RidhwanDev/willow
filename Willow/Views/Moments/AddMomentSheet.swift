import SwiftData
import SwiftUI

struct AddMomentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]

    @State private var selectedParentIndex = 0
    @State private var selectedType: MomentType = .rest
    @State private var title = ""
    @State private var date = Date()
    @State private var durationMinutes = 30
    @State private var selectedQuality: TimeQuality = .protectedTime
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WillowSpacing.large) {
                    parentPicker
                    titleField
                    momentTypes
                    qualityPicker
                    detailFields
                    PrimaryButton(title: "Add to Willow", systemImage: "leaf.fill", action: save)
                }
                .padding(WillowSpacing.large)
            }
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Add Moment")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var parentPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Who was this for?")
                .font(.headline)
                .foregroundStyle(WillowColors.ink)
            Picker("Parent", selection: $selectedParentIndex) {
                ForEach(parents.indices, id: \.self) { index in
                    Text(parents[index].name).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var titleField: some View {
        TextField("Gym, coffee, rest, date night...", text: $title)
            .font(.headline)
            .padding(16)
            .background(WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var momentTypes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Moment type")
                .font(.headline)
                .foregroundStyle(WillowColors.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 10)], spacing: 10) {
                ForEach(MomentType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        Label(type.title, systemImage: type.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 10)
                            .background(selectedType == type ? WillowColors.deepLeaf : WillowColors.softCream, in: Capsule())
                            .foregroundStyle(selectedType == type ? .white : WillowColors.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var qualityPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time quality")
                .font(.headline)
                .foregroundStyle(WillowColors.ink)

            ForEach(TimeQuality.allCases) { quality in
                Button {
                    selectedQuality = quality
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedQuality == quality ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedQuality == quality ? WillowColors.deepLeaf : WillowColors.muted)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(quality.title)
                                .font(.headline)
                            Text(quality.explanation)
                                .font(.caption)
                                .foregroundStyle(WillowColors.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .foregroundStyle(WillowColors.ink)
                    .padding(14)
                    .background(WillowColors.softCream.opacity(selectedQuality == quality ? 1 : 0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var detailFields: some View {
        VStack(spacing: 14) {
            DatePicker("When", selection: $date)
            Stepper("Duration: \(durationMinutes) minutes", value: $durationMinutes, in: 5...300, step: 5)
            TextField("Notes optional", text: $notes, axis: .vertical)
                .lineLimit(3...5)
        }
        .font(.body)
        .padding(16)
        .background(WillowColors.softCream.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func save() {
        guard parents.indices.contains(selectedParentIndex) else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let moment = WellbeingMoment(
            parentId: parents[selectedParentIndex].id,
            type: selectedType,
            title: cleanTitle.isEmpty ? selectedType.title : cleanTitle,
            date: date,
            durationMinutes: durationMinutes,
            timeQuality: selectedQuality,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        modelContext.insert(moment)
        dismiss()
    }
}
