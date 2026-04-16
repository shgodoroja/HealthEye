import SwiftUI

struct ScoreBreakdownView: View {
    let result: AttentionScoreResult

    private var bucketColor: Color {
        switch result.bucket {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attention Score")
                    .font(.headline)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(Int(result.total))")
                        .font(.title2.bold())
                    Text(result.bucket.displayName)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(bucketColor.opacity(0.2), in: Capsule())
                        .foregroundStyle(bucketColor)
                }
            }

            VStack(spacing: 6) {
                subscoreBar(label: "Recovery (Sleep)", value: result.recoverySleep, maxValue: 13.5)
                subscoreBar(label: "Recovery (HRV)", value: result.recoveryHrv, maxValue: 18.0)
                subscoreBar(label: "Recovery (RHR)", value: result.recoveryRestingHr, maxValue: 13.5)
                subscoreBar(label: "Workout", value: result.workout, maxValue: 25.0)
                subscoreBar(label: "Steps", value: result.steps, maxValue: 15.0)
                subscoreBar(label: "Completeness", value: result.completenessPenalty, maxValue: 15.0)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func subscoreBar(label: String, value: Double, maxValue: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .frame(width: 120, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(value: value, maxValue: maxValue))
                        .frame(width: max(0, geo.size.width * min(1, value / maxValue)), height: 8)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f", value))
                .font(.caption.monospacedDigit())
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func barColor(value: Double, maxValue: Double) -> Color {
        let ratio = value / maxValue
        if ratio > 0.7 { return .red }
        if ratio > 0.4 { return .orange }
        return .green
    }
}
