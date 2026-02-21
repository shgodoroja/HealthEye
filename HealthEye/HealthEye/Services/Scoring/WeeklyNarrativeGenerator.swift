import Foundation

struct NarrativeResult: Sendable {
    let summary: String
    let suggestedMessages: [String]
}

struct WeeklyNarrativeGenerator {

    /// Generates a human-readable "What changed this week" summary from metric trend.
    static func generate(trend: MetricTrend, alerts: [AlertResult]) -> NarrativeResult {
        let summary = generateSummary(trend: trend)
        let messages = generateMessages(alerts: alerts, trend: trend)
        return NarrativeResult(summary: summary, suggestedMessages: messages)
    }

    private static func generateSummary(trend: MetricTrend) -> String {
        var changes: [(String, Double)] = []

        if let delta = trend.sleepDelta {
            changes.append(("Sleep", delta))
        }
        if let delta = trend.hrvDelta {
            changes.append(("HRV", delta))
        }
        if let delta = trend.restingHrDelta {
            changes.append(("Resting heart rate", delta))
        }
        if let delta = trend.workoutDelta {
            changes.append(("Workout minutes", delta))
        }
        if let delta = trend.stepsDelta {
            changes.append(("Daily steps", delta))
        }

        // Sort by absolute magnitude (largest changes first)
        changes.sort { abs($0.1) > abs($1.1) }

        // Filter to significant changes (>= 5% absolute)
        let significant = changes.filter { abs($0.1) >= 5.0 }

        guard !significant.isEmpty else {
            return "No major changes this week."
        }

        // Take top 3
        let top = significant.prefix(3)
        let sentences = top.map { name, delta -> String in
            if delta < 0 {
                return String(format: "%@ dropped %.0f%% compared to the prior 4 weeks.", name, abs(delta))
            } else {
                return String(format: "%@ increased %.0f%% compared to the prior 4 weeks.", name, delta)
            }
        }

        return sentences.joined(separator: " ")
    }

    private static func generateMessages(alerts: [AlertResult], trend: MetricTrend) -> [String] {
        let maxSeverity = alerts.map(\.severity).max(by: { severityRank($0) < severityRank($1) })

        switch maxSeverity {
        case .high:
            return highSeverityMessages(alerts: alerts)
        case .medium:
            return mediumSeverityMessages(alerts: alerts)
        case .low:
            return lowSeverityMessages()
        case nil:
            return encouragementMessages(trend: trend)
        }
    }

    private static func severityRank(_ severity: AlertSeverity) -> Int {
        switch severity {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    private static func highSeverityMessages(alerts: [AlertResult]) -> [String] {
        [
            "Hey, I noticed some changes in your recovery data this week. How are you feeling? Let's check in and see if we need to adjust anything.",
            "Your recent health data shows some shifts in sleep, HRV, and heart rate. No need to worry — just want to make sure you're doing okay. Can we chat?",
            "I'm seeing some recovery indicators that suggest your body might need extra rest. Let's talk about how you're feeling and whether we should ease up this week.",
        ]
    }

    private static func mediumSeverityMessages(alerts: [AlertResult]) -> [String] {
        let hasActivityDrop = alerts.contains { $0.ruleCode == "AR-003" }
        let hasSleepDrop = alerts.contains { $0.ruleCode == "AR-002" }

        if hasSleepDrop && hasActivityDrop {
            return [
                "I noticed your sleep and activity were both down this past week. How's everything going? Let's chat about what might help.",
                "Your data shows a dip in sleep and workouts recently. Just checking in — is everything okay on your end?",
            ]
        } else if hasSleepDrop {
            return [
                "I noticed your sleep has been down this week. How are you feeling? Any changes in your routine we should talk about?",
                "Your sleep data shows a noticeable drop recently. Just checking in — anything going on that might be affecting your rest?",
            ]
        } else {
            return [
                "Your workout minutes were down this past week. Everything okay? Let's see if we need to adjust the plan.",
                "I noticed a drop in your activity levels recently. Just checking in — any changes in schedule or how you're feeling?",
            ]
        }
    }

    private static func lowSeverityMessages() -> [String] {
        [
            "Quick check-in: your steps were down a bit this week. Nothing major, but wanted to see how you're doing!",
            "I noticed your daily steps dipped this week. Just a heads-up — how are things going?",
        ]
    }

    private static func encouragementMessages(trend: MetricTrend) -> [String] {
        [
            "Great week! Your numbers are looking solid. Keep up the good work!",
            "Everything looks steady this week. Nice consistency — that's what builds long-term results.",
            "Your data looks great this week. Any goals you want to push on next week?",
        ]
    }
}
