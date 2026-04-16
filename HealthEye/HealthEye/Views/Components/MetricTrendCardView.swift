import SwiftUI

struct MetricTrendCardView: View {
    let metricName: String
    let unit: String
    let recentAvg: Double?
    let baselineAvg: Double?
    let delta: Double?

    private var trendArrow: String {
        guard let delta = delta else { return "minus" }
        if delta > 2 { return "arrow.up.right" }
        if delta < -2 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var trendColor: Color {
        guard let delta = delta else { return .secondary }
        // For most metrics, decreasing is bad. For RHR, increasing is bad.
        let isNegativeBad = metricName != "Resting HR"
        if isNegativeBad {
            if delta < -10 { return .red }
            if delta < -5 { return .orange }
            if delta > 5 { return .green }
        } else {
            if delta > 10 { return .red }
            if delta > 5 { return .orange }
            if delta < -5 { return .green }
        }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metricName)
                    .font(.subheadline.bold())
                Spacer()
                if let delta = delta {
                    HStack(spacing: 2) {
                        Image(systemName: trendArrow)
                            .accessibilityHidden(true)
                        Text(String(format: "%+.0f%%", delta))
                    }
                    .font(.caption.bold())
                    .foregroundStyle(trendColor)
                    .accessibilityElement(children: .combine)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent (7d)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let avg = recentAvg {
                        Text(String(format: "%.1f %@", avg, unit))
                            .font(.callout.monospacedDigit())
                    } else {
                        Text("—")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Baseline (28d)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let avg = baselineAvg {
                        Text(String(format: "%.1f %@", avg, unit))
                            .font(.callout.monospacedDigit())
                    } else {
                        Text("—")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
