import SwiftData
import SwiftUI

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
        ZStack {
            WillowColors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: WillowSpacing.large) {
                Spacer(minLength: 20)

                WillowTreeView(state: .growing)
                    .frame(height: 280)

                VStack(spacing: 12) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(WillowColors.ink)

                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(WillowColors.muted)
                        .lineSpacing(4)
                }
                .padding(.horizontal, WillowSpacing.large)

                content

                VStack(spacing: 10) {
                    PrimaryButton(title: step == 3 ? "Enter Willow" : "Continue", systemImage: step == 3 ? "leaf.fill" : "arrow.right") {
                        advance()
                    }

                    Button("Use demo family") {
                        SampleDataService.seedIfNeeded(modelContext: modelContext, parents: parents)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WillowColors.deepLeaf)
                    .opacity(step < 2 ? 1 : 0)
                }
                .padding(.horizontal, WillowSpacing.large)

                Spacer(minLength: 24)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            EmptyView()
        case 1:
            SoftCard {
                Text("Willow helps your family protect time to recharge, reconnect, and stay yourselves while raising children.")
                    .font(.headline)
                    .foregroundStyle(WillowColors.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, WillowSpacing.large)
        case 2:
            VStack(spacing: 14) {
                TextField("Parent 1", text: $parentOneName)
                TextField("Parent 2", text: $parentTwoName)
            }
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, WillowSpacing.large)
        default:
            VStack(alignment: .leading, spacing: 16) {
                companionPicker(title: parentOneName, selection: $parentOneCompanion)
                companionPicker(title: parentTwoName, selection: $parentTwoCompanion)
            }
            .padding(.horizontal, WillowSpacing.large)
        }
    }

    private func companionPicker(title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.isEmpty ? "Parent" : title)
                .font(.headline)
                .foregroundStyle(WillowColors.ink)

            Picker(title, selection: selection) {
                ForEach(companionTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var title: String {
        switch step {
        case 0: "Meet Willow"
        case 1: "A living reminder"
        case 2: "Add your family"
        default: "Choose companions"
        }
    }

    private var message: String {
        switch step {
        case 0: "A calm place to notice whether your family is getting the care it needs."
        case 1: "Your family willow reflects protected time, rest, friendship, hobbies, couple time, and connection."
        case 2: "Start with two parents or carers. You can adjust the names for the demo."
        default: "Each parent has a small companion around the tree."
        }
    }

    private func advance() {
        if step < 3 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                step += 1
            }
        } else {
            createFamily()
        }
    }

    private func createFamily() {
        let first = ParentProfile(name: parentOneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Parent 1" : parentOneName, companionName: companionName(for: parentOneCompanion), companionType: parentOneCompanion)
        let second = ParentProfile(name: parentTwoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Parent 2" : parentTwoName, companionName: companionName(for: parentTwoCompanion), companionType: parentTwoCompanion)
        modelContext.insert(first)
        modelContext.insert(second)
    }

    private func companionName(for type: String) -> String {
        switch type {
        case "Fox": "Fenn"
        case "Rabbit": "Luma"
        case "Squirrel": "Moss"
        case "Otter": "River"
        default: "Willow"
        }
    }
}
