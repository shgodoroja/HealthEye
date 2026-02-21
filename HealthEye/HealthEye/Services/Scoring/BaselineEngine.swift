import Foundation

struct MetricWindow: Sendable {
    let sleepAvg: Double?
    let hrvAvg: Double?
    let restingHrAvg: Double?
    let workoutAvg: Double?
    let stepsAvg: Double?
    let dayCount: Int
}

struct MetricTrend: Sendable {
    let recent: MetricWindow
    let baseline: MetricWindow
    let sleepDelta: Double?
    let hrvDelta: Double?
    let restingHrDelta: Double?
    let workoutDelta: Double?
    let stepsDelta: Double?
}

struct BaselineEngine {
    private static var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Computes metric trend comparing recent 7 days vs prior 28-day baseline.
    /// - Parameters:
    ///   - metrics: All daily metrics for a client
    ///   - referenceDate: The "today" date (excluded from windows). Defaults to current date.
    /// - Returns: MetricTrend with averages and percentage deltas
    static func computeTrend(
        metrics: [MetricDaily],
        referenceDate: Date = Date()
    ) -> MetricTrend {
        let cal = calendar
        let today = cal.startOfDay(for: referenceDate)

        // Recent window: days 1-7 before today (last 7 full days)
        guard let recentStart = cal.date(byAdding: .day, value: -7, to: today),
              let baselineStart = cal.date(byAdding: .day, value: -35, to: today) else {
            let empty = MetricWindow(sleepAvg: nil, hrvAvg: nil, restingHrAvg: nil, workoutAvg: nil, stepsAvg: nil, dayCount: 0)
            return MetricTrend(recent: empty, baseline: empty, sleepDelta: nil, hrvDelta: nil, restingHrDelta: nil, workoutDelta: nil, stepsDelta: nil)
        }

        let recentMetrics = metrics.filter { m in
            let day = cal.startOfDay(for: m.date)
            return day >= recentStart && day < today
        }

        let baselineMetrics = metrics.filter { m in
            let day = cal.startOfDay(for: m.date)
            return day >= baselineStart && day < recentStart
        }

        let recentWindow = computeWindow(from: recentMetrics)
        let baselineWindow = computeWindow(from: baselineMetrics)

        return MetricTrend(
            recent: recentWindow,
            baseline: baselineWindow,
            sleepDelta: percentageDelta(recent: recentWindow.sleepAvg, baseline: baselineWindow.sleepAvg),
            hrvDelta: percentageDelta(recent: recentWindow.hrvAvg, baseline: baselineWindow.hrvAvg),
            restingHrDelta: percentageDelta(recent: recentWindow.restingHrAvg, baseline: baselineWindow.restingHrAvg),
            workoutDelta: percentageDelta(recent: recentWindow.workoutAvg, baseline: baselineWindow.workoutAvg),
            stepsDelta: percentageDelta(recent: recentWindow.stepsAvg, baseline: baselineWindow.stepsAvg)
        )
    }

    static func computeWindow(from metrics: [MetricDaily]) -> MetricWindow {
        MetricWindow(
            sleepAvg: average(of: metrics.compactMap(\.sleepMinutes)),
            hrvAvg: average(of: metrics.compactMap(\.hrvMs)),
            restingHrAvg: average(of: metrics.compactMap(\.restingHrBpm)),
            workoutAvg: average(of: metrics.compactMap(\.workoutMinutes)),
            stepsAvg: average(of: metrics.compactMap(\.steps)),
            dayCount: metrics.count
        )
    }

    private static func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    static func percentageDelta(recent: Double?, baseline: Double?) -> Double? {
        guard let r = recent, let b = baseline, b != 0 else { return nil }
        return (r - b) / b * 100.0
    }
}
