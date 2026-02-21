import Testing
import Foundation
@testable import HealthEye

struct MetricDailyTests {
    @Test func completenessScoreWithAllMetrics() {
        let metric = MetricDaily(
            date: Date(),
            sleepMinutes: 420,
            hrvMs: 50,
            restingHrBpm: 60,
            workoutMinutes: 30,
            steps: 8000
        )
        #expect(metric.completenessScore == 1.0)
    }

    @Test func completenessScoreWithNoMetrics() {
        let metric = MetricDaily(date: Date())
        #expect(metric.completenessScore == 0.0)
    }

    @Test func completenessScoreWithPartialMetrics() {
        let metric = MetricDaily(
            date: Date(),
            sleepMinutes: 420,
            steps: 8000
        )
        #expect(metric.completenessScore == 0.4) // 2/5
    }

    @Test func nilMetricsAreNotZero() {
        let metric = MetricDaily(date: Date())
        #expect(metric.sleepMinutes == nil)
        #expect(metric.hrvMs == nil)
        #expect(metric.restingHrBpm == nil)
        #expect(metric.workoutMinutes == nil)
        #expect(metric.steps == nil)
    }
}
