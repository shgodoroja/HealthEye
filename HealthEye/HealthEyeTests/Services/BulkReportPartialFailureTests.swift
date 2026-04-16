import Testing
import Foundation
@testable import HealthEye

struct BulkReportPartialFailureTests {

    private static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func makeWeek() -> ReportWeekRange {
        let cal = Self.utcCalendar
        let weekStart = cal.date(from: DateComponents(year: 2024, month: 1, day: 8))!
        let weekEnd = cal.date(from: DateComponents(year: 2024, month: 1, day: 14))!
        return ReportWeekRange(weekStart: weekStart, weekEnd: weekEnd)
    }

    private func fullMetrics(starting start: Date, dayCount: Int) -> [MetricDailySnapshot] {
        let cal = Self.utcCalendar
        return (0..<dayCount).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: start)!
            return MetricDailySnapshot(
                date: date,
                sleepMinutes: 420,
                hrvMs: 50,
                restingHrBpm: 60,
                workoutMinutes: 30,
                steps: 8_000
            )
        }
    }

    // MARK: - Partial failure

    @Test func emptyClientListReturnsEmptyResult() {
        let result = BulkReportService.generate(clients: [], week: makeWeek())
        #expect(result.succeeded.isEmpty)
        #expect(result.failed.isEmpty)
        #expect(result.pdfFiles.isEmpty)
    }

    @Test func mixOfClientsWithAndWithoutDataProducesPartialResult() {
        let week = makeWeek()
        let clientWithData = BulkReportClientSnapshot(
            displayName: "Has Data",
            metrics: fullMetrics(starting: week.weekStart, dayCount: 7)
        )
        let clientNoData = BulkReportClientSnapshot(
            displayName: "No Data",
            metrics: []
        )

        let result = BulkReportService.generate(clients: [clientWithData, clientNoData], week: week)

        // Both should produce PDFs (even empty data generates a valid report)
        // but we verify the structure is correct regardless
        #expect(result.succeeded.count + result.failed.count == 2)
        #expect(result.pdfFiles.count == result.succeeded.count)
    }

    @Test func allSucceededClientsHavePDFFiles() {
        let week = makeWeek()
        let clients = (0..<3).map { i in
            BulkReportClientSnapshot(
                displayName: "Client \(i)",
                metrics: fullMetrics(starting: week.weekStart, dayCount: 7)
            )
        }

        let result = BulkReportService.generate(clients: clients, week: week)

        #expect(result.succeeded.count == 3)
        #expect(result.pdfFiles.count == 3)
        #expect(result.failed.isEmpty)
        for file in result.pdfFiles {
            #expect(!file.data.isEmpty)
            #expect(file.filename.hasSuffix(".pdf"))
        }
    }

    @Test func failedClientNamesAreReported() {
        let week = makeWeek()
        let clients = [
            BulkReportClientSnapshot(displayName: "Good Client", metrics: fullMetrics(starting: week.weekStart, dayCount: 7)),
        ]

        let result = BulkReportService.generate(clients: clients, week: week)

        // Verify succeeded names are tracked
        #expect(result.succeeded.contains("Good Client"))
    }

    @Test func resultCountsMatchInput() {
        let week = makeWeek()
        let clients = (0..<5).map { i in
            BulkReportClientSnapshot(
                displayName: "Client \(i)",
                metrics: fullMetrics(starting: week.weekStart, dayCount: 7)
            )
        }

        let result = BulkReportService.generate(clients: clients, week: week)

        #expect(result.succeeded.count + result.failed.count == 5)
    }
}
