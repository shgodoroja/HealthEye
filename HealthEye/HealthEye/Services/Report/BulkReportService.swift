import Foundation
import AppKit
import SwiftData

struct BulkReportResult {
    let succeeded: [String]   // client display names
    let failed: [String]      // client display names
}

struct BulkReportService {

    /// Generates one PDF per client for the given week and saves them all to `directory`.
    /// Returns immediately with a result summary.
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

        // Ask user to pick a folder once before iterating
        guard let folderURL = pickFolder() else {
            return BulkReportResult(succeeded: [], failed: [])
        }

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
            let fileURL = folderURL.appendingPathComponent(filename)

            do {
                try PDFReportGenerator.save(data: pdfData, to: fileURL)

                let report = GeneratedReport(
                    client: client,
                    weekStart: weekStart,
                    weekEnd: weekEnd,
                    pdfPath: fileURL.path
                )
                context.insert(report)
                succeeded.append(client.displayName)
            } catch {
                failed.append(client.displayName)
            }
        }

        if !succeeded.isEmpty {
            try? context.save()
            AnalyticsService.track("bulk_reports_exported", properties: [
                "count": String(succeeded.count),
            ])
        }

        return BulkReportResult(succeeded: succeeded, failed: failed)
    }

    // MARK: - Private helpers

    private static func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Save Reports Here"
        panel.message = "Choose the folder where all PDF reports will be saved."
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func sanitizedFilename(for clientName: String, weekStart: Date) -> String {
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
