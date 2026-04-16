import Foundation
import SwiftData

// MARK: - Result types

struct BulkReportResult {
    let succeeded: [String]        // client display names
    let failed: [String]           // client display names
    /// Generated PDFs ready to be saved/shared by the caller.
    let pdfFiles: [(filename: String, data: Data)]
}

// MARK: - Service

struct BulkReportService {

    /// Generates one PDF per client for the given week.
    ///
    /// The caller is responsible for saving or sharing the returned `pdfFiles`
    /// in a platform-appropriate way (folder picker on macOS, share sheet on iPadOS).
    static func generate(
        clients: [Client],
        weekStart: Date,
        context: ModelContext
    ) -> BulkReportResult {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

        var succeeded: [String] = []
        var failed: [String] = []
        var pdfFiles: [(filename: String, data: Data)] = []

        for client in clients {
            let metrics = client.metrics
            let trend = BaselineEngine.computeTrend(
                metrics: metrics,
                referenceDate: weekEnd.addingTimeInterval(86400)
            )
            let completeness = averageCompleteness(for: client)
            let scoreResult = AttentionScoreCalculator.calculate(
                trend: trend,
                completenessScore: completeness
            )
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

            let pdfData = PDFReportGenerator.generate(data: reportData)
            guard !pdfData.isEmpty else {
                failed.append(client.displayName)
                continue
            }

            let filename = sanitizedFilename(for: client.displayName, weekStart: weekStart)
            pdfFiles.append((filename: filename, data: pdfData))
            succeeded.append(client.displayName)
        }

        return BulkReportResult(succeeded: succeeded, failed: failed, pdfFiles: pdfFiles)
    }

    /// Persists a successfully exported PDF as a `GeneratedReport` record.
    static func recordExport(
        client: Client,
        weekStart: Date,
        weekEnd: Date,
        pdfPath: String,
        context: ModelContext
    ) {
        let report = GeneratedReport(
            client: client,
            weekStart: weekStart,
            weekEnd: weekEnd,
            pdfPath: pdfPath
        )
        context.insert(report)
        try? context.save()
    }

    // MARK: - Private helpers

    static func sanitizedFilename(for clientName: String, weekStart: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let name = clientName
            .components(separatedBy: .whitespaces).joined()
            .components(separatedBy: .punctuationCharacters).joined()
        return "\(name)_Week_\(formatter.string(from: weekStart)).pdf"
    }

    private static func averageCompleteness(for client: Client) -> Double {
        let records = client.completenessRecords
        guard !records.isEmpty else { return 0 }
        return records.map(\.completenessScore).reduce(0, +) / Double(records.count)
    }
}
