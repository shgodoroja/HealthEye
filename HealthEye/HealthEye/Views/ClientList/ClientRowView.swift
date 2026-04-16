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
        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: Date())
        guard let record = client.completenessRecords.first(where: { $0.weekStart == currentWeekStart }) else {
            return nil
        }
        return record.completenessScore
    }

    private var topAlert: AlertEvent? {
        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: Date())
        return client.alerts
            .filter { $0.weekStart == currentWeekStart }
            .sorted { severityOrder($0.severity) > severityOrder($1.severity) }
            .first
    }

    private func severityOrder(_ severity: AlertSeverity) -> Int {
        switch severity {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
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
                            .accessibilityLabel("\(alert.severity.rawValue) alert")
                        Text(alert.explanationText)
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
