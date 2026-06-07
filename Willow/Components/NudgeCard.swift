import SwiftUI

struct NudgeCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "hands.sparkles.fill")
                .font(.title3)
                .foregroundStyle(WillowColors.amber)
                .frame(width: 34, height: 34)
                .background(WillowColors.amber.opacity(0.16), in: Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(WillowColors.ink)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(WillowColors.softCream.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(WillowColors.amber.opacity(0.24), lineWidth: 1)
        }
    }
}
