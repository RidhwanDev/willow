import SwiftData
import SwiftUI

struct ProtectView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProtectedTimePlan.startDate) private var plans: [ProtectedTimePlan]
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var showingAddPlan = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WillowSpacing.large) {
                    SoftCard {
                        Text("Protected time means you are genuinely off-duty. No baby monitor, no half-listening, no waiting for the next wake-up.")
                            .font(.headline)
                            .foregroundStyle(WillowColors.ink)
                            .lineSpacing(4)
                    }

                    PrimaryButton(title: "Add Protected Time", systemImage: "plus.circle.fill") {
                        showingAddPlan = true
                    }

                    section(title: "Upcoming", plans: plans.filter { !$0.isCompleted })
                    section(title: "Completed", plans: plans.filter { $0.isCompleted })
                }
                .padding(WillowSpacing.large)
            }
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Protect")
        }
        .sheet(isPresented: $showingAddPlan) {
            AddProtectedTimeSheet()
        }
    }

    private func section(title: String, plans: [ProtectedTimePlan]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(WillowColors.ink)

            if plans.isEmpty {
                Text(title == "Upcoming" ? "No protected time scheduled yet." : "Completed time will gather here gently.")
                    .font(.subheadline)
                    .foregroundStyle(WillowColors.muted)
                    .padding(.vertical, 6)
            } else {
                ForEach(plans) { plan in
                    planCard(plan)
                }
            }
        }
    }

    private func planCard(_ plan: ProtectedTimePlan) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: plan.isCompleted ? "checkmark.seal.fill" : "shield.fill")
                .font(.title3)
                .foregroundStyle(plan.isCompleted ? WillowColors.leaf : WillowColors.amber)
                .frame(width: 42, height: 42)
                .background(WillowColors.softCream, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("\(plan.startDate.formatted(.dateTime.weekday(.wide).hour().minute()))-\(plan.endDate.formatted(.dateTime.hour().minute()))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WillowColors.deepLeaf)

                Text("\(name(for: plan.parentId)): \(plan.title)")
                    .font(.headline)
                    .foregroundStyle(WillowColors.ink)

                if let protector = plan.protectedByParentId {
                    Text("Protected by: \(name(for: protector))")
                        .font(.subheadline)
                        .foregroundStyle(WillowColors.muted)
                }
            }

            Spacer()

            if !plan.isCompleted {
                Button {
                    plan.isCompleted = true
                } label: {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(WillowColors.deepLeaf, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(WillowColors.softCream.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func name(for id: UUID) -> String {
        parents.first { $0.id == id }?.name ?? "Parent"
    }
}
