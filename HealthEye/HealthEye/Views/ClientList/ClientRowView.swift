import SwiftUI
import SwiftData

struct ClientRowView: View {
    let client: Client
    let attentionScore: Double?

    private var lastImportDate: Date? {
        client.imports
            .filter { $0.importStatus == .success }
            .map(\.importedAt)
            .max()
    }

    private var currentWeekCompleteness: Double? {
        let score = CompletenessCalculator.score(
            for: CompletenessCalculator.mondayOfWeek(containing: Date()),
            metrics: client.metrics
        )
        return client.metrics.isEmpty && score == 0 ? nil : score
    }

    private var topAlert: AlertResult? {
        let trend = BaselineEngine.computeTrend(metrics: client.metrics)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        return alerts.first
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(client.displayName)
                    .font(.headline)

                if let alert = topAlert {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(alertColor(alert.severity))
                            .frame(width: 6, height: 6)
                        Text(alert.explanation)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else if let lastImport = lastImportDate {
                    Text("Last import: \(lastImport, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No imports yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let score = attentionScore {
                AttentionScoreBadgeView(score: score)
            } else if let completeness = currentWeekCompleteness {
                CompletenessIndicatorView(score: completeness)
            }
        }
        .padding(.vertical, 2)
    }

    private func alertColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}
