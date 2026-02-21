import Foundation
import SwiftData

struct AlertResult: Sendable {
    let ruleCode: String
    let severity: AlertSeverity
    let explanation: String
}

struct AlertRuleEngine {

    /// Evaluates all alert rules against a metric trend.
    static func evaluate(trend: MetricTrend) -> [AlertResult] {
        var results: [AlertResult] = []

        if let alert = evaluateAR001(trend: trend) {
            results.append(alert)
        }
        if let alert = evaluateAR002(trend: trend) {
            results.append(alert)
        }
        if let alert = evaluateAR003(trend: trend) {
            results.append(alert)
        }
        if let alert = evaluateAR004(trend: trend) {
            results.append(alert)
        }

        return results
    }

    // AR-001: Recovery Risk (high)
    // HRV <= -12% AND RHR >= +8% AND Sleep <= -10%
    private static func evaluateAR001(trend: MetricTrend) -> AlertResult? {
        guard let hrvDelta = trend.hrvDelta,
              let rhrDelta = trend.restingHrDelta,
              let sleepDelta = trend.sleepDelta else {
            return nil
        }

        guard hrvDelta <= -12.0 && rhrDelta >= 8.0 && sleepDelta <= -10.0 else {
            return nil
        }

        let explanation = String(
            format: "HRV dropped %.0f%% while resting heart rate rose %.0f%% and sleep decreased %.0f%%",
            abs(hrvDelta), rhrDelta, abs(sleepDelta)
        )
        return AlertResult(ruleCode: "AR-001", severity: .high, explanation: explanation)
    }

    // AR-002: Sleep Drop (medium)
    // Sleep <= -15%
    private static func evaluateAR002(trend: MetricTrend) -> AlertResult? {
        guard let sleepDelta = trend.sleepDelta, sleepDelta <= -15.0 else {
            return nil
        }

        let explanation = String(
            format: "Sleep dropped %.0f%% compared to the prior 4 weeks",
            abs(sleepDelta)
        )
        return AlertResult(ruleCode: "AR-002", severity: .medium, explanation: explanation)
    }

    // AR-003: Activity Drop (medium)
    // Workout <= -20%
    private static func evaluateAR003(trend: MetricTrend) -> AlertResult? {
        guard let workoutDelta = trend.workoutDelta, workoutDelta <= -20.0 else {
            return nil
        }

        let explanation = String(
            format: "Workout minutes dropped %.0f%% compared to the prior 4 weeks",
            abs(workoutDelta)
        )
        return AlertResult(ruleCode: "AR-003", severity: .medium, explanation: explanation)
    }

    // AR-004: Step Drop (low)
    // Steps <= -20%
    private static func evaluateAR004(trend: MetricTrend) -> AlertResult? {
        guard let stepsDelta = trend.stepsDelta, stepsDelta <= -20.0 else {
            return nil
        }

        let explanation = String(
            format: "Daily steps dropped %.0f%% compared to the prior 4 weeks",
            abs(stepsDelta)
        )
        return AlertResult(ruleCode: "AR-004", severity: .low, explanation: explanation)
    }

    /// Persists alert results as AlertEvent records (upsert by client + weekStart + ruleCode).
    @MainActor
    static func saveAlerts(
        alerts: [AlertResult],
        client: Client,
        weekStart: Date,
        context: ModelContext
    ) throws {
        let clientID = client.id

        for alert in alerts {
            let code = alert.ruleCode
            let descriptor = FetchDescriptor<AlertEvent>(
                predicate: #Predicate<AlertEvent> { event in
                    event.client?.id == clientID &&
                    event.weekStart == weekStart &&
                    event.ruleCode == code
                }
            )
            let existing = try context.fetch(descriptor).first

            if let existing {
                existing.severity = alert.severity
                existing.explanationText = alert.explanation
            } else {
                let event = AlertEvent(
                    client: client,
                    weekStart: weekStart,
                    ruleCode: alert.ruleCode,
                    severity: alert.severity,
                    explanationText: alert.explanation
                )
                context.insert(event)
            }
        }
    }
}
