import SwiftUI

struct ImportStepResultView: View {
    let importService: AppleHealthImportService
    let onDone: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            switch importService.state {
            case .completed(let summary):
                successView(summary: summary)
            case .failed(let message):
                failureView(message: message)
            default:
                EmptyView()
            }

            Spacer()

            HStack {
                if case .failed = importService.state {
                    Button("Try Again") {
                        onRetry()
                    }
                    .controlSize(.large)
                }

                Spacer()

                Button("Done") {
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("import-done")
            }
        }
        .padding(24)
    }

    private func successView(summary: ImportSummary) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Import Successful")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityIdentifier("import-success-title")

            VStack(alignment: .leading, spacing: 8) {
                summaryRow("Days of data", value: "\(summary.totalDays)")
                summaryRow("Records parsed", value: summary.totalRecordsParsed.formatted())

                if let start = summary.dateRangeStart, let end = summary.dateRangeEnd {
                    summaryRow("Date range",
                        value: "\(start.formatted(.dateTime.month(.abbreviated).day().year())) — \(end.formatted(.dateTime.month(.abbreviated).day().year()))")
                }

                Divider()

                Text("Metrics Coverage")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                metricsRow("Sleep", days: summary.metricsBreakdown.daysWithSleep, total: summary.totalDays)
                metricsRow("HRV", days: summary.metricsBreakdown.daysWithHRV, total: summary.totalDays)
                metricsRow("Resting HR", days: summary.metricsBreakdown.daysWithRestingHR, total: summary.totalDays)
                metricsRow("Workout", days: summary.metricsBreakdown.daysWithWorkout, total: summary.totalDays)
                metricsRow("Steps", days: summary.metricsBreakdown.daysWithSteps, total: summary.totalDays)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Import Failed")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityIdentifier("import-failed-title")

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }

    private func metricsRow(_ name: String, days: Int, total: Int) -> some View {
        HStack {
            Text(name)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(days)/\(total) days")
                .fontWeight(.medium)
            CompletenessIndicatorView(score: total > 0 ? Double(days) / Double(total) : 0)
        }
        .font(.callout)
    }
}
