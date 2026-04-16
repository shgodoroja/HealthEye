import XCTest
@testable import HealthEye

final class BulkReportServiceTests: XCTestCase {
    func testReportDataUsesSelectedWeekCompleteness() {
        let weekStart = Calendar.utc.date(from: DateComponents(year: 2024, month: 1, day: 8))!
        let weekEnd = Calendar.utc.date(from: DateComponents(year: 2024, month: 1, day: 14))!
        let priorWeekStart = Calendar.utc.date(from: DateComponents(year: 2024, month: 1, day: 1))!

        var metrics = fullMetrics(starting: priorWeekStart, dayCount: 7)
        metrics.append(MetricDailySnapshot(
            date: weekStart,
            sleepMinutes: 420,
            hrvMs: 50,
            restingHrBpm: 60,
            workoutMinutes: 30,
            steps: 8_000
        ))

        let client = BulkReportClientSnapshot(displayName: "Week Specific", metrics: metrics)
        let reportData = BulkReportService.reportData(
            for: client,
            week: ReportWeekRange(weekStart: weekStart, weekEnd: weekEnd)
        )

        XCTAssertEqual(reportData.completenessScore, 1.0 / 7.0, accuracy: 0.001)
    }

    func testDuplicateClientNamesGenerateUniqueFilenames() {
        let weekStart = Calendar.utc.date(from: DateComponents(year: 2024, month: 1, day: 8))!
        let firstFilename = BulkReportService.sanitizedFilename(
            for: "Taylor Client",
            clientID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            weekStart: weekStart
        )
        let secondFilename = BulkReportService.sanitizedFilename(
            for: "Taylor Client",
            clientID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            weekStart: weekStart
        )

        XCTAssertNotEqual(firstFilename, secondFilename)
    }

    private func fullMetrics(starting start: Date, dayCount: Int) -> [MetricDailySnapshot] {
        (0..<dayCount).map { offset in
            let date = Calendar.utc.date(byAdding: .day, value: offset, to: start)!
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
}

private extension Calendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
