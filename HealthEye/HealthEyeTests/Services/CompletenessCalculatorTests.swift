import Testing
import Foundation
@testable import HealthEye

struct CompletenessCalculatorTests {
    private func makeDate(_ string: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        return df.date(from: string)!
    }

    private func makeMetric(
        date: String,
        sleep: Double? = nil,
        hrv: Double? = nil,
        restingHr: Double? = nil,
        workout: Double? = nil,
        steps: Double? = nil
    ) -> MetricDaily {
        MetricDaily(
            date: makeDate(date),
            sleepMinutes: sleep,
            hrvMs: hrv,
            restingHrBpm: restingHr,
            workoutMinutes: workout,
            steps: steps
        )
    }

    @Test func fullWeekScoresOne() {
        // 7 days (Mon Feb 9 to Sun Feb 15), all 5 metrics present each day → score = 1.0
        let metrics = (9...15).map { day in
            makeMetric(
                date: "2026-02-\(String(format: "%02d", day))",
                sleep: 420,
                hrv: 50,
                restingHr: 60,
                workout: 30,
                steps: 8000
            )
        }

        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        #expect(weeks.count == 1)
        #expect(weeks[0].score == 1.0)
    }

    @Test func emptyMetricsReturnsEmpty() {
        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: [])
        #expect(weeks.isEmpty)
    }

    @Test func partialWeekScoresCorrectly() {
        // 3 days with only steps → score = (3/7 + 0/7 + 0/7 + 0/7 + 0/7) / 5
        let metrics = [
            makeMetric(date: "2026-02-10", steps: 5000),
            makeMetric(date: "2026-02-11", steps: 6000),
            makeMetric(date: "2026-02-12", steps: 7000),
        ]

        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        #expect(weeks.count == 1)

        let expected = (3.0 / 7.0) / 5.0
        #expect(abs(weeks[0].score - expected) < 0.001)
    }

    @Test func granularScoringPerMetric() {
        // 2 days: one with sleep+steps, one with only hrv
        let metrics = [
            makeMetric(date: "2026-02-10", sleep: 420, steps: 8000),
            makeMetric(date: "2026-02-11", hrv: 50),
        ]

        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        #expect(weeks.count == 1)

        let week = weeks[0]
        #expect(week.daysWithSleep == 1)
        #expect(week.daysWithHRV == 1)
        #expect(week.daysWithRestingHR == 0)
        #expect(week.daysWithWorkout == 0)
        #expect(week.daysWithSteps == 1)
    }

    @Test func notesGeneratedForGaps() {
        let metrics = [
            makeMetric(date: "2026-02-10", steps: 5000),
        ]

        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        let notes = weeks[0].notes

        #expect(notes.contains("Missing Sleep for 7 of 7 days"))
        #expect(notes.contains("Missing HRV for 7 of 7 days"))
        #expect(notes.contains("Missing Steps for 6 of 7 days"))
    }

    @Test func weekBoundaryGrouping() {
        // Feb 10 (Mon) and Feb 17 (Mon) are different weeks
        let metrics = [
            makeMetric(date: "2026-02-10", steps: 5000),
            makeMetric(date: "2026-02-17", steps: 6000),
        ]

        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        #expect(weeks.count == 2)
    }

    @Test func completeDataNotes() {
        // Mon Feb 9 to Sun Feb 15 = one full ISO week
        let metrics = (9...15).map { day in
            makeMetric(
                date: "2026-02-\(String(format: "%02d", day))",
                sleep: 420,
                hrv: 50,
                restingHr: 60,
                workout: 30,
                steps: 8000
            )
        }

        let weeks = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        #expect(weeks[0].notes == "Complete data for this week")
    }
}
