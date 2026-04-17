import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

// MARK: - FileDocument wrapper for .fileExporter

struct PDFFile: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Main view

struct ReportPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [CoachAccount]

    let client: Client

    @State private var weekStart: Date = CompletenessCalculator.mondayOfWeek(containing: Date())
    @State private var state: ReportState = .loading
    @State private var pdfData: Data?
    @State private var showingPaywall = false
    @State private var showingExporter = false
    @State private var exportFileName = ""
    @State private var didInitializeWeek = false

    private var account: CoachAccount? {
        accounts.first
    }

    private enum ReportState: Equatable {
        case loading
        case preview
        case exported(String)
        case error(String)
    }

    private var selectedWeek: ReportWeekRange {
        ReportSchedule.weekContaining(
            weekStart,
            timezoneIdentifier: account?.timezone ?? TimeZone.current.identifier,
            reportEndDay: account?.defaultReportDay ?? 7
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding()
                .background(.background)

            Divider()

            switch state {
            case .loading:
                Spacer()
                ProgressView("Generating report...")
                Spacer()

            case .preview:
                if let pdfData {
                    PDFPreview(data: pdfData)
                }

            case .exported(let name):
                if let pdfData {
                    PDFPreview(data: pdfData)
                        .overlay(alignment: .bottom) {
                            exportedBanner(name: name)
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
                    Button("Retry") { generateReport() }
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
#if os(macOS)
        .frame(minWidth: 700, minHeight: 600)
#endif
        .onAppear {
            if !didInitializeWeek, let account {
                weekStart = ReportSchedule.latestCompletedWeek(
                    timezoneIdentifier: account.timezone,
                    reportEndDay: account.defaultReportDay
                ).weekStart
                didInitializeWeek = true
            }
            generateReport()
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: pdfData.map { PDFFile(data: $0) },
            contentType: .pdf,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success(let url):
                let report = GeneratedReport(
                    client: client,
                    weekStart: selectedWeek.weekStart,
                    weekEnd: selectedWeek.weekEnd,
                    pdfPath: url.path
                )
                modelContext.insert(report)
                try? modelContext.save()
                AnalyticsService.track("report_exported", account: account)
                state = .exported(url.lastPathComponent)
            case .failure(let error):
                state = .error("Failed to save: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Text("Weekly Report")
                .font(.headline)
                .accessibilityIdentifier("report-title")

            Spacer()

            DatePicker("Week of", selection: $weekStart, displayedComponents: .date)
#if os(macOS)
                .datePickerStyle(.field)
                .frame(width: 220)
#else
                .datePickerStyle(.compact)
#endif
                .onChange(of: weekStart) {
                    weekStart = ReportSchedule.weekContaining(
                        weekStart,
                        timezoneIdentifier: account?.timezone ?? TimeZone.current.identifier,
                        reportEndDay: account?.defaultReportDay ?? 7
                    ).weekStart
                    generateReport()
                }

            Button("Export PDF") {
                if let account, TrialManager.canGenerateReports(account: account) {
                    exportFileName = sanitizedFileName()
                    showingExporter = true
                } else {
                    showingPaywall = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pdfData == nil)
            .accessibilityIdentifier("report-export-button")

            Button("Close") { dismiss() }
                .accessibilityIdentifier("report-close-button")
        }
    }

    private func exportedBanner(name: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Saved: \(name)")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding()
    }

    // MARK: - Report generation

    private func generateReport() {
        state = .loading
        pdfData = nil

        let metrics = client.metrics
        let week = selectedWeek
        let trend = BaselineEngine.computeTrend(
            metrics: metrics,
            referenceDate: week.dayAfterWeekEnd
        )
        let completeness = CompletenessCalculator.score(
            from: week.weekStart,
            to: week.weekEnd,
            metrics: metrics
        )
        let scoreResult = AttentionScoreCalculator.calculate(trend: trend, completenessScore: completeness)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let narrative = WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)

        let reportData = ReportData(
            clientName: client.displayName,
            weekStart: week.weekStart,
            weekEnd: week.weekEnd,
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

    private func sanitizedFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let name = client.displayName.replacingOccurrences(of: " ", with: "")
        return "\(name)_Week_\(formatter.string(from: selectedWeek.weekStart)).pdf"
    }
}

// MARK: - Cross-platform PDF canvas

#if os(macOS)
private struct PDFPreview: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(data: data)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(data: data)
    }
}
#else
private struct PDFPreview: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(data: data)
    }
}
#endif
