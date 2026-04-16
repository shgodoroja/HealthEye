import SwiftUI

struct AlertPanelView: View {
    let alerts: [AlertResult]

    private func severityColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func severityIcon(_ severity: AlertSeverity) -> String {
        switch severity {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Alerts")
                .font(.headline)

            if alerts.isEmpty {
                Text("No active alerts this week.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(alerts, id: \.ruleCode) { alert in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: severityIcon(alert.severity))
                            .foregroundStyle(severityColor(alert.severity))
                            .frame(width: 16)
                            .accessibilityLabel("\(alert.severity.rawValue) severity")

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(alert.ruleCode)
                                    .font(.caption.bold())
                                Text(alert.severity.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(
                                        severityColor(alert.severity).opacity(0.15),
                                        in: Capsule()
                                    )
                            }
                            Text(alert.explanation)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
