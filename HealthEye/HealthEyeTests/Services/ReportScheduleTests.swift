import XCTest
@testable import HealthEye

final class ReportScheduleTests: XCTestCase {
    func testLatestCompletedWeekUsesConfiguredReportEndDay() {
        let referenceDate = DateComponents(
            calendar: Calendar.utc,
            timeZone: TimeZone(identifier: "UTC"),
            year: 2024,
            month: 1,
            day: 10,
            hour: 12
        ).date!

        let range = ReportSchedule.latestCompletedWeek(
            referenceDate: referenceDate,
            timezoneIdentifier: "UTC",
            reportEndDay: 1
        )

        XCTAssertEqual(localDateString(range.weekStart, timezone: "UTC"), "2024-01-02")
        XCTAssertEqual(localDateString(range.weekEnd, timezone: "UTC"), "2024-01-08")
    }

    func testLatestCompletedWeekUsesCoachTimezone() {
        let referenceDate = DateComponents(
            calendar: Calendar.utc,
            timeZone: TimeZone(identifier: "UTC"),
            year: 2024,
            month: 1,
            day: 7,
            hour: 23,
            minute: 30
        ).date!

        let range = ReportSchedule.latestCompletedWeek(
            referenceDate: referenceDate,
            timezoneIdentifier: "Pacific/Auckland",
            reportEndDay: 1
        )

        XCTAssertEqual(localDateString(range.weekEnd, timezone: "Pacific/Auckland"), "2024-01-08")
    }

    private func localDateString(_ date: Date, timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
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
