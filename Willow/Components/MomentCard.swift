import SwiftUI

struct MomentCard: View {
    let moment: WellbeingMoment
    let parentName: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: moment.type.symbolName)
                .font(.title3)
                .foregroundStyle(WillowColors.deepLeaf)
                .frame(width: 44, height: 44)
                .background(WillowColors.leaf.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(moment.title)
                    .font(.headline)
                    .foregroundStyle(WillowColors.ink)

                Text("\(parentName) · \(moment.timeQuality.title) · \(moment.durationMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(WillowColors.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(WillowColors.softCream.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }
}
