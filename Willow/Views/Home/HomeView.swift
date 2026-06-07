import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \ParentProfile.createdAt) private var parents: [ParentProfile]
    @Query(sort: \WellbeingMoment.date, order: .reverse) private var moments: [WellbeingMoment]
    @State private var showingAddMoment = false
    @State private var showingProtectTime = false

    private let engine = WellbeingEngine()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: WillowSpacing.large) {
                    header
                    willowWorld
                    actionRow
                    NudgeCard(text: engine.nudge(for: parents, moments: moments))
                }
                .padding(.horizontal, WillowSpacing.large)
                .padding(.top, WillowSpacing.large)
                .padding(.bottom, 36)
            }
            .background(WillowColors.backgroundGradient.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddMoment) {
            AddMomentSheet()
        }
        .sheet(isPresented: $showingProtectTime) {
            AddProtectedTimeSheet()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Willow is \(treeState.title)")
                .font(.largeTitle.bold())
                .foregroundStyle(WillowColors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(engine.statusText(for: treeState))
                .font(.body)
                .foregroundStyle(WillowColors.muted)
                .lineSpacing(4)
        }
    }

    private var willowWorld: some View {
        ZStack(alignment: .bottom) {
            WillowTreeView(state: treeState)
                .padding(.top, 8)

            HStack(alignment: .bottom) {
                if let first = parents.first {
                    CompanionView(parent: first, state: engine.parentState(for: first, moments: moments), delay: 0.1)
                }

                Spacer()

                if parents.count > 1 {
                    CompanionView(parent: parents[1], state: engine.parentState(for: parents[1], moments: moments), delay: 0.65)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .frame(height: 380)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                showingAddMoment = true
            } label: {
                Label("Add Moment", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(WillowColors.deepLeaf, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                showingProtectTime = true
            } label: {
                Label("Protect Time", systemImage: "shield.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(WillowColors.amber.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(WillowColors.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private var treeState: FamilyTreeState {
        engine.familyTreeState(for: parents, moments: moments)
    }
}
