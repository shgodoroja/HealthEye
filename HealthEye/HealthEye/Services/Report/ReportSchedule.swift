import Foundation

struct ReportWeekRange: Sendable, Equatable {
    let weekStart: Date
    let weekEnd: Date

    nonisolated var dayAfterWeekEnd: Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(byAdding: .day, value: 1, to: weekEnd) ?? weekEnd
    }
}

struct ReportSchedule {
    static func latestCompletedWeek(
        referenceDate: Date = Date(),
        timezoneIdentifier: String,
        reportEndDay: Int
    ) -> ReportWeekRange {
        let calendar = calendar(timezoneIdentifier: timezoneIdentifier)
        let day = calendar.startOfDay(for: referenceDate)
        let weekday = isoWeekday(for: day, calendar: calendar)
        let normalizedReportEndDay = normalizedISOWeekday(reportEndDay)
        let daysSinceEnd = (weekday - normalizedReportEndDay + 7) % 7
        let end = calendar.date(byAdding: .day, value: -daysSinceEnd, to: day) ?? day
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return ReportWeekRange(weekStart: start, weekEnd: end)
    }

    static func weekContaining(
        _ date: Date,
        timezoneIdentifier: String,
        reportEndDay: Int
    ) -> ReportWeekRange {
        let calendar = calendar(timezoneIdentifier: timezoneIdentifier)
        let day = calendar.startOfDay(for: date)
        let weekday = isoWeekday(for: day, calendar: calendar)
        let normalizedReportEndDay = normalizedISOWeekday(reportEndDay)
        let daysUntilEnd = (normalizedReportEndDay - weekday + 7) % 7
        let end = calendar.date(byAdding: .day, value: daysUntilEnd, to: day) ?? day
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return ReportWeekRange(weekStart: start, weekEnd: end)
    }

    private static func calendar(timezoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: timezoneIdentifier) ?? TimeZone(identifier: "UTC")!
        return calendar
    }

    private static func isoWeekday(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 ? 7 : weekday - 1
    }

    private static func normalizedISOWeekday(_ day: Int) -> Int {
        min(max(day, 1), 7)
    }
}
