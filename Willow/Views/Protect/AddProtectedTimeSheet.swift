import SwiftData
import SwiftUI

struct AddProtectedTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]

    @State private var selectedParentIndex = 0
    @State private var selectedProtectorIndex = 1
    @State private var title = ""
    @State private var startDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WillowSpacing.large) {
                    picker(title: "Who is this for?", selection: $selectedParentIndex)

                    TextField("What will they do?", text: $title)
                        .font(.headline)
                        .padding(16)
                        .background(WillowColors.softCream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(spacing: 14) {
                        DatePicker("Start time", selection: $startDate)
                        DatePicker("End time", selection: $endDate)
                    }
                    .padding(16)
                    .background(WillowColors.softCream.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    picker(title: "Who is protecting this time?", selection: $selectedProtectorIndex)

                    PrimaryButton(title: "Save Protected Time", systemImage: "shield.fill", action: save)
                }
                .padding(WillowSpacing.large)
            }
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Protect Time")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if parents.count > 1, selectedParentIndex == selectedProtectorIndex {
                selectedProtectorIndex = 1
            }
        }
    }

    private func picker(title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(WillowColors.ink)
            Picker(title, selection: selection) {
                ForEach(parents.indices, id: \.self) { index in
                    Text(parents[index].name).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func save() {
        guard parents.indices.contains(selectedParentIndex) else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let adjustedEnd = max(endDate, startDate.addingTimeInterval(30 * 60))
        let protectorId = parents.indices.contains(selectedProtectorIndex) ? parents[selectedProtectorIndex].id : nil
        let plan = ProtectedTimePlan(
            parentId: parents[selectedParentIndex].id,
            protectedByParentId: protectorId,
            title: cleanTitle.isEmpty ? "Protected time" : cleanTitle,
            startDate: startDate,
            endDate: adjustedEnd
        )
        modelContext.insert(plan)
        dismiss()
    }
}
