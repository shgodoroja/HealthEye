import Testing
import Foundation
@testable import HealthEye

struct WeeklyNarrativeGeneratorTests {

    private func makeTrend(
        sleepDelta: Double? = nil,
        hrvDelta: Double? = nil,
        rhrDelta: Double? = nil,
        workoutDelta: Double? = nil,
        stepsDelta: Double? = nil
    ) -> MetricTrend {
        let emptyWindow = MetricWindow(sleepAvg: nil, hrvAvg: nil, restingHrAvg: nil, workoutAvg: nil, stepsAvg: nil, dayCount: 0)
        return MetricTrend(
            recent: emptyWindow,
            baseline: emptyWindow,
            sleepDelta: sleepDelta,
            hrvDelta: hrvDelta,
            restingHrDelta: rhrDelta,
            workoutDelta: workoutDelta,
            stepsDelta: stepsDelta
        )
    }

    // MARK: - Narrative with drops

    @Test func narrativeDescribesDrops() {
        let trend = makeTrend(sleepDelta: -18, workoutDelta: -25)
        let result = WeeklyNarrativeGenerator.generate(trend: trend, alerts: [])
        #expect(result.summary.contains("dropped"))
        #expect(result.summary.contains("Workout"))
        #expect(result.summary.contains("Sleep"))
    }

    // MARK: - Narrative with improvements

    @Test func narrativeDescribesImprovements() {
        let trend = makeTrend(stepsDelta: 15)
        let result = WeeklyNarrativeGenerator.generate(trend: trend, alerts: [])
        #expect(result.summary.contains("increased"))
        #expect(result.summary.contains("steps"))
    }

    // MARK: - No significant changes

    @Test func noChangesMessage() {
        let trend = makeTrend(sleepDelta: 2, hrvDelta: -1, stepsDelta: 3)
        let result = WeeklyNarrativeGenerator.generate(trend: trend, alerts: [])
        #expect(result.summary == "No major changes this week.")
    }

    // MARK: - Message generation per alert profile

    @Test func highSeverityAlertsGenerateConcernedMessages() {
        let trend = makeTrend(sleepDelta: -20, hrvDelta: -15, rhrDelta: 12)
        let alerts = [
            AlertResult(ruleCode: "AR-001", severity: .high, explanation: "Recovery risk detected")
        ]
        let result = WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)
        #expect(result.suggestedMessages.count >= 2)
        #expect(result.suggestedMessages.first?.contains("recovery") == true || result.suggestedMessages.first?.contains("changes") == true)
    }
}
