import SwiftData
import SwiftUI

struct MomentsView: View {
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @State private var showingAddMoment = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if moments.isEmpty {
                            emptyState
                        } else {
                            ForEach(groupedDays, id: \.self) { day in
                                Text(day.formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.headline)
                                    .foregroundStyle(WillowColors.deepLeaf)
                                    .padding(.top, 8)

                                ForEach(momentsForDay(day)) { moment in
                                    MomentCard(moment: moment, parentName: name(for: moment.parentId))
                                }
                            }
                        }
                    }
                    .padding(WillowSpacing.large)
                    .padding(.bottom, 90)
                }

                Button {
                    showingAddMoment = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(WillowColors.deepLeaf, in: Circle())
                        .shadow(color: WillowColors.deepLeaf.opacity(0.28), radius: 16, x: 0, y: 8)
                }
                .padding(WillowSpacing.large)
            }
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Moments")
        }
        .sheet(isPresented: $showingAddMoment) {
            AddMomentSheet()
        }
    }

    private var emptyState: some View {
        SoftCard {
            VStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.largeTitle)
                    .foregroundStyle(WillowColors.leaf)
                Text("Small moments matter. Add something you did to recharge.")
                    .font(.headline)
                    .foregroundStyle(WillowColors.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var groupedDays: [Date] {
        let days = moments.map { Calendar.current.startOfDay(for: $0.date) }
        return Array(Set(days)).sorted(by: >)
    }

    private func momentsForDay(_ day: Date) -> [WellbeingMoment] {
        moments.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func name(for id: UUID) -> String {
        parents.first { $0.id == id }?.name ?? "Parent"
    }
}
