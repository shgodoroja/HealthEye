import SwiftUI

struct CompletenessIndicatorView: View {
    let score: Double

    private var color: Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .help(String(format: "%.0f%% data complete this week", score * 100))
            .accessibilityLabel(String(format: "%.0f percent data complete this week", score * 100))
    }
}
