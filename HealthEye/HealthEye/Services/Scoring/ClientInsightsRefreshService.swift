import Foundation
import SwiftData

struct ClientInsightsSnapshot {
    let weeklyCompleteness: [WeeklyCompleteness]
    let currentWeekStart: Date
    let currentWeekCompleteness: Double
    let trend: MetricTrend
    let attentionResult: AttentionScoreResult
    let alerts: [AlertResult]
    let narrative: NarrativeResult
}

struct ClientInsightsRefreshService {
    @MainActor
    static func refresh(
        client: Client,
        context: ModelContext,
        referenceDate: Date = Date()
    ) throws -> ClientInsightsSnapshot {
        let metrics = try fetchMetrics(for: client.id, context: context)
        let weeklyCompleteness = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)
        try CompletenessCalculator.saveCompleteness(
            weeklyData: weeklyCompleteness,
            client: client,
            context: context
        )

        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: referenceDate)
        let currentWeekCompleteness = completenessScore(
            for: currentWeekStart,
            within: weeklyCompleteness
        )

        let trend = BaselineEngine.computeTrend(metrics: metrics, referenceDate: referenceDate)
        let attentionResult = AttentionScoreCalculator.calculate(
            trend: trend,
            completenessScore: currentWeekCompleteness
        )
        try AttentionScoreCalculator.saveScore(
            result: attentionResult,
            client: client,
            weekStart: currentWeekStart,
            context: context
        )

        let alerts = AlertRuleEngine.evaluate(trend: trend)
        try AlertRuleEngine.saveAlerts(
            alerts: alerts,
            client: client,
            weekStart: currentWeekStart,
            context: context
        )

        try context.save()

        return ClientInsightsSnapshot(
            weeklyCompleteness: weeklyCompleteness,
            currentWeekStart: currentWeekStart,
            currentWeekCompleteness: currentWeekCompleteness,
            trend: trend,
            attentionResult: attentionResult,
            alerts: alerts,
            narrative: WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)
        )
    }

    static func completenessScore(
        for weekStart: Date,
        within weeklyData: [WeeklyCompleteness]
    ) -> Double {
        weeklyData.first(where: { $0.weekStart == weekStart })?.score ?? 0
    }

    @MainActor
    private static func fetchMetrics(
        for clientID: UUID,
        context: ModelContext
    ) throws -> [MetricDaily] {
        let descriptor = FetchDescriptor<MetricDaily>(
            predicate: #Predicate<MetricDaily> { metric in
                metric.client?.id == clientID
            }
        )
        return try context.fetch(descriptor)
    }
}
