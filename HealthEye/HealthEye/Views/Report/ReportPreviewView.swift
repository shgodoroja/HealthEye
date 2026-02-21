import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct ReportPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [CoachAccount]

    let client: Client

    @State private var weekStart: Date = CompletenessCalculator.mondayOfWeek(containing: Date())
    @State private var state: ReportState = .loading
    @State private var pdfData: Data?
    @State private var showingPaywall = false

    private var account: CoachAccount? {
        accounts.first
    }

    private enum ReportState: Equatable {
        case loading
        case preview
        case exported(String)
        case error(String)
    }

    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Content
            switch state {
            case .loading:
                Spacer()
                ProgressView("Generating report...")
                Spacer()

            case .preview:
                if let pdfData {
                    PDFPreview(data: pdfData)
                }

            case .exported(let path):
                if let pdfData {
                    PDFPreview(data: pdfData)
                        .overlay(alignment: .bottom) {
                            exportedBanner(path: path)
                        }
                }

            case .error(let message):
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Report generation failed")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        generateReport()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            if let account {
                PaywallView(account: account)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            generateReport()
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Weekly Report")
                .font(.headline)

            Spacer()

            DatePicker(
                "Week of",
                selection: $weekStart,
                displayedComponents: .date
            )
            .datePickerStyle(.field)
            .frame(width: 220)
            .onChange(of: weekStart) {
                // Snap to Monday
                weekStart = CompletenessCalculator.mondayOfWeek(containing: weekStart)
                generateReport()
            }

            Button("Export PDF") {
                if let account, TrialManager.canGenerateReports(account: account) {
                    exportPDF()
                } else {
                    showingPaywall = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pdfData == nil)

            Button("Close") {
                dismiss()
            }
        }
    }

    private func exportedBanner(path: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Saved to: \(path)")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding()
    }

    // MARK: - Actions

    private func generateReport() {
        state = .loading
        pdfData = nil

        let metrics = client.metrics
        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: weekEnd.addingTimeInterval(86400))

        let completeness = averageCompleteness()
        let scoreResult = AttentionScoreCalculator.calculate(trend: trend, completenessScore: completeness)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let narrative = WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)

        let reportData = ReportData(
            clientName: client.displayName,
            weekStart: weekStart,
            weekEnd: weekEnd,
            trend: trend,
            scoreResult: scoreResult,
            alerts: alerts,
            narrative: narrative,
            completenessScore: completeness
        )

        let generated = PDFReportGenerator.generate(data: reportData)

        if generated.isEmpty {
            state = .error("Failed to generate PDF data.")
        } else {
            pdfData = generated
            state = .preview
        }
    }

    private func exportPDF() {
        guard let pdfData else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = sanitizedFileName()
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            do {
                try PDFReportGenerator.save(data: pdfData, to: url)

                // Persist GeneratedReport record
                let report = GeneratedReport(
                    client: client,
                    weekStart: weekStart,
                    weekEnd: weekEnd,
                    pdfPath: url.path
                )
                modelContext.insert(report)

                AnalyticsService.track("report_exported")
                state = .exported(url.path)
            } catch {
                state = .error("Failed to save: \(error.localizedDescription)")
            }
        }
    }

    private func sanitizedFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let name = client.displayName.replacingOccurrences(of: " ", with: "")
        return "\(name)_Week_\(formatter.string(from: weekStart)).pdf"
    }

    private func averageCompleteness() -> Double {
        let records = client.completenessRecords
        guard !records.isEmpty else { return 0 }
        return records.map(\.completenessScore).reduce(0, +) / Double(records.count)
    }
}

// MARK: - PDF Preview Wrapper

private struct PDFPreview: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}
