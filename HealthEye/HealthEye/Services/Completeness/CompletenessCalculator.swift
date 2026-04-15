import Foundation
import SwiftData

struct WeeklyCompleteness: Sendable {
    let weekStart: Date
    let daysWithSleep: Int
    let daysWithHRV: Int
    let daysWithRestingHR: Int
    let daysWithWorkout: Int
    let daysWithSteps: Int
    let totalDays: Int
    let score: Double
    let notes: String
}

struct CompletenessCalculator {
    private static var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    static func calculateWeeklyCompleteness(metrics: [MetricDaily]) -> [WeeklyCompleteness] {
        guard !metrics.isEmpty else { return [] }

        // Group by ISO week (Monday start)
        var weekGroups: [Date: [MetricDaily]] = [:]

        for metric in metrics {
            let weekStart = mondayOfWeek(containing: metric.date)
            weekGroups[weekStart, default: []].append(metric)
        }

        return weekGroups.keys.sorted().map { weekStart in
            let days = weekGroups[weekStart]!
            return calculateForWeek(weekStart: weekStart, days: days)
        }
    }

    static func mondayOfWeek(containing date: Date) -> Date {
        let cal = calendar
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? cal.startOfDay(for: date)
    }

    static func score(
        for weekStart: Date,
        metrics: [MetricDaily]
    ) -> Double {
        let normalizedWeekStart = mondayOfWeek(containing: weekStart)
        return calculateWeeklyCompleteness(metrics: metrics)
            .first(where: { $0.weekStart == normalizedWeekStart })?
            .score ?? 0
    }

    private static func calculateForWeek(weekStart: Date, days: [MetricDaily]) -> WeeklyCompleteness {
        let totalDays = days.count
        let daysWithSleep = days.filter { $0.sleepMinutes != nil }.count
        let daysWithHRV = days.filter { $0.hrvMs != nil }.count
        let daysWithRestingHR = days.filter { $0.restingHrBpm != nil }.count
        let daysWithWorkout = days.filter { $0.workoutMinutes != nil }.count
        let daysWithSteps = days.filter { $0.steps != nil }.count

        // Score = mean of (days_with_data / 7) across 5 metrics
        let metricScores = [
            Double(daysWithSleep) / 7.0,
            Double(daysWithHRV) / 7.0,
            Double(daysWithRestingHR) / 7.0,
            Double(daysWithWorkout) / 7.0,
            Double(daysWithSteps) / 7.0,
        ]
        let score = metricScores.reduce(0, +) / 5.0

        // Generate notes for gaps
        var gaps: [String] = []
        let metricNames = ["Sleep", "HRV", "Resting HR", "Workout", "Steps"]
        let metricDays = [daysWithSleep, daysWithHRV, daysWithRestingHR, daysWithWorkout, daysWithSteps]

        for (name, count) in zip(metricNames, metricDays) where count < 7 {
            let missing = 7 - count
            gaps.append("Missing \(name) for \(missing) of 7 days")
        }

        let notes = gaps.isEmpty ? "Complete data for this week" : gaps.joined(separator: ". ")

        return WeeklyCompleteness(
            weekStart: weekStart,
            daysWithSleep: daysWithSleep,
            daysWithHRV: daysWithHRV,
            daysWithRestingHR: daysWithRestingHR,
            daysWithWorkout: daysWithWorkout,
            daysWithSteps: daysWithSteps,
            totalDays: totalDays,
            score: score,
            notes: notes
        )
    }

    @MainActor
    static func saveCompleteness(
        weeklyData: [WeeklyCompleteness],
        client: Client,
        context: ModelContext
    ) throws {
        for week in weeklyData {
            // Upsert
            let clientID = client.id
            let weekStart = week.weekStart
            let descriptor = FetchDescriptor<MetricCompleteness>(
                predicate: #Predicate<MetricCompleteness> { mc in
                    mc.client?.id == clientID && mc.weekStart == weekStart
                }
            )
            let existing = try context.fetch(descriptor).first

            let record: MetricCompleteness
            if let existing {
                record = existing
            } else {
                record = MetricCompleteness(client: client, weekStart: week.weekStart)
                context.insert(record)
            }

            record.hasSleep = week.daysWithSleep > 0
            record.hasHrv = week.daysWithHRV > 0
            record.hasRestingHr = week.daysWithRestingHR > 0
            record.hasWorkout = week.daysWithWorkout > 0
            record.hasSteps = week.daysWithSteps > 0
            record.completenessScore = week.score
            record.notes = week.notes
        }
    }
}
