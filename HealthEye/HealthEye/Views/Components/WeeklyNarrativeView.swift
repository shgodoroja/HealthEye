import SwiftUI

struct WeeklyNarrativeView: View {
    let narrative: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What Changed This Week")
                .font(.headline)

            Text(narrative)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
