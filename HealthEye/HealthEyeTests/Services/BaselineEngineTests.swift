import Testing
import Foundation
@testable import HealthEye

struct BaselineEngineTests {

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func makeDate(daysBeforeReference days: Int, reference: Date) -> Date {
        Self.calendar.date(byAdding: .day, value: -days, to: Self.calendar.startOfDay(for: reference))!
    }

    private func makeMetric(date: Date, sleep: Double? = nil, hrv: Double? = nil, rhr: Double? = nil, workout: Double? = nil, steps: Double? = nil) -> MetricDaily {
        MetricDaily(date: date, sleepMinutes: sleep, hrvMs: hrv, restingHrBpm: rhr, workoutMinutes: workout, steps: steps)
    }

    // MARK: - Window date ranges

    @Test func recentWindowCoversLast7Days() {
        let ref = Self.calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        var metrics: [MetricDaily] = []
        for day in 1...7 {
            metrics.append(makeMetric(date: makeDate(daysBeforeReference: day, reference: ref), steps: 1000))
        }
        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: ref)
        #expect(trend.recent.dayCount == 7)
        #expect(trend.recent.stepsAvg == 1000)
    }

    @Test func baselineWindowCovers28DaysPrior() {
        let ref = Self.calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!
        var metrics: [MetricDaily] = []
        // Baseline: days 8..35 before ref
        for day in 8...35 {
            metrics.append(makeMetric(date: makeDate(daysBeforeReference: day, reference: ref), steps: 2000))
        }
        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: ref)
        #expect(trend.baseline.dayCount == 28)
        #expect(trend.baseline.stepsAvg == 2000)
    }

    // MARK: - Averages with missing data

    @Test func averagesOnlyOverNonNilValues() {
        let ref = Self.calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        let metrics = [
            makeMetric(date: makeDate(daysBeforeReference: 1, reference: ref), sleep: 420, steps: 8000),
            makeMetric(date: makeDate(daysBeforeReference: 2, reference: ref), sleep: 480),
            makeMetric(date: makeDate(daysBeforeReference: 3, reference: ref), steps: 10000),
        ]
        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: ref)
        #expect(trend.recent.sleepAvg == 450) // (420+480)/2
        #expect(trend.recent.stepsAvg == 9000) // (8000+10000)/2
        #expect(trend.recent.hrvAvg == nil)
    }

    // MARK: - Delta calculation

    @Test func deltaCalculationPercentage() {
        let ref = Self.calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!
        var metrics: [MetricDaily] = []
        // Recent: 7 days, steps=800
        for day in 1...7 {
            metrics.append(makeMetric(date: makeDate(daysBeforeReference: day, reference: ref), steps: 800))
        }
        // Baseline: 28 days, steps=1000
        for day in 8...35 {
            metrics.append(makeMetric(date: makeDate(daysBeforeReference: day, reference: ref), steps: 1000))
        }
        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: ref)
        #expect(trend.stepsDelta != nil)
        #expect(trend.stepsDelta! == -20.0) // (800-1000)/1000*100
    }

    // MARK: - Both windows empty

    @Test func bothWindowsEmptyReturnsNilDeltas() {
        let trend = BaselineEngine.computeTrend(metrics: [])
        #expect(trend.recent.dayCount == 0)
        #expect(trend.baseline.dayCount == 0)
        #expect(trend.sleepDelta == nil)
        #expect(trend.hrvDelta == nil)
        #expect(trend.stepsDelta == nil)
    }

    // MARK: - Single day data

    @Test func singleDayDataProducesRecentAvg() {
        let ref = Self.calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        let metrics = [
            makeMetric(date: makeDate(daysBeforeReference: 3, reference: ref), hrv: 55)
        ]
        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: ref)
        #expect(trend.recent.hrvAvg == 55)
        #expect(trend.recent.dayCount == 1)
        #expect(trend.hrvDelta == nil) // no baseline data
    }

    // MARK: - Nil handling

    @Test func nilDeltaWhenBaselineIsZero() {
        let delta = BaselineEngine.percentageDelta(recent: 100, baseline: 0)
        #expect(delta == nil)
    }

    @Test func nilDeltaWhenEitherWindowMissing() {
        let delta = BaselineEngine.percentageDelta(recent: nil, baseline: 100)
        #expect(delta == nil)
    }
}
