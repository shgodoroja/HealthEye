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
            .help(String(format: "%.0f%% complete", score * 100))
    }
}
