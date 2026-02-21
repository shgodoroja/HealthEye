import Testing
import Foundation
@testable import HealthEye

struct AlertRuleEngineTests {

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

    // MARK: - AR-001 Recovery Risk

    @Test func ar001TriggersWhenAllThreeConditionsMet() {
        let trend = makeTrend(sleepDelta: -12, hrvDelta: -15, rhrDelta: 10)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar001 = alerts.first { $0.ruleCode == "AR-001" }
        #expect(ar001 != nil)
        #expect(ar001?.severity == .high)
    }

    @Test func ar001DoesNotTriggerWithOnlyTwoConditions() {
        // HRV down but RHR not up enough
        let trend = makeTrend(sleepDelta: -12, hrvDelta: -15, rhrDelta: 5)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar001 = alerts.first { $0.ruleCode == "AR-001" }
        #expect(ar001 == nil)
    }

    // MARK: - AR-002 Sleep Drop

    @Test func ar002TriggersWhenSleepDropsAtLeast15Percent() {
        let trend = makeTrend(sleepDelta: -18)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar002 = alerts.first { $0.ruleCode == "AR-002" }
        #expect(ar002 != nil)
        #expect(ar002?.severity == .medium)
    }

    @Test func ar002DoesNotTriggerBelowThreshold() {
        let trend = makeTrend(sleepDelta: -10)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar002 = alerts.first { $0.ruleCode == "AR-002" }
        #expect(ar002 == nil)
    }

    // MARK: - AR-003 Activity Drop

    @Test func ar003TriggersWhenWorkoutDropsAtLeast20Percent() {
        let trend = makeTrend(workoutDelta: -25)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar003 = alerts.first { $0.ruleCode == "AR-003" }
        #expect(ar003 != nil)
        #expect(ar003?.severity == .medium)
    }

    @Test func ar003DoesNotTriggerBelowThreshold() {
        let trend = makeTrend(workoutDelta: -15)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar003 = alerts.first { $0.ruleCode == "AR-003" }
        #expect(ar003 == nil)
    }

    // MARK: - AR-004 Step Drop

    @Test func ar004TriggersWhenStepsDropAtLeast20Percent() {
        let trend = makeTrend(stepsDelta: -22)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar004 = alerts.first { $0.ruleCode == "AR-004" }
        #expect(ar004 != nil)
        #expect(ar004?.severity == .low)
    }

    @Test func ar004DoesNotTriggerBelowThreshold() {
        let trend = makeTrend(stepsDelta: -18)
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let ar004 = alerts.first { $0.ruleCode == "AR-004" }
        #expect(ar004 == nil)
    }

    // MARK: - No data

    @Test func noAlertsWithNoData() {
        let trend = makeTrend()
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        #expect(alerts.isEmpty)
    }
}
