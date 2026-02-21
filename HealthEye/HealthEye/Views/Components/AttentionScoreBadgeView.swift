import SwiftUI

struct AttentionScoreBadgeView: View {
    let score: Double
    let bucket: AttentionBucket

    init(score: Double) {
        self.score = score
        self.bucket = AttentionBucket.from(score: score)
    }

    private var backgroundColor: Color {
        switch bucket {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }

    private var foregroundColor: Color {
        switch bucket {
        case .low: return .white
        case .medium: return .black
        case .high: return .white
        }
    }

    var body: some View {
        Text("\(Int(score))")
            .font(.caption.bold())
            .foregroundStyle(foregroundColor)
            .frame(width: 32, height: 20)
            .background(backgroundColor.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
            .help("Attention score: \(Int(score)) (\(bucket.displayName))")
    }
}
