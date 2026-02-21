import Testing
import Foundation
@testable import HealthEye

struct AttentionScoreCalculatorTests {

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

    // MARK: - Perfect data → low score

    @Test func perfectDataProducesLowScore() {
        // No drops, full completeness
        let trend = makeTrend(sleepDelta: 0, hrvDelta: 0, rhrDelta: 0, workoutDelta: 0, stepsDelta: 0)
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 1.0)
        #expect(result.total < 40)
        #expect(result.bucket == .low)
    }

    // MARK: - All metrics dropping → high score

    @Test func allMetricsDroppingProducesHighScore() {
        let trend = makeTrend(sleepDelta: -30, hrvDelta: -30, rhrDelta: 30, workoutDelta: -30, stepsDelta: -30)
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 0.0)
        #expect(result.total >= 70)
        #expect(result.bucket == .high)
    }

    // MARK: - Missing data penalty

    @Test func missingDataContributesFullPenalty() {
        // All deltas nil = full penalty per component. completeness = 0
        let trend = makeTrend()
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 0.0)
        #expect(result.total == 100) // All components at maximum
        #expect(result.completenessPenalty == 15.0)
    }

    // MARK: - Determinism

    @Test func sameInputProducesSameOutput() {
        let trend = makeTrend(sleepDelta: -10, hrvDelta: -5, rhrDelta: 3, workoutDelta: -15, stepsDelta: -8)
        let result1 = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 0.8)
        let result2 = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 0.8)
        #expect(result1.total == result2.total)
        #expect(result1.sourceDataHash == result2.sourceDataHash)
    }

    // MARK: - Subscore weights

    @Test func workoutWeightIs25Points() {
        // Only workout dropping at max (-30%), everything else stable
        let trend = makeTrend(sleepDelta: 0, hrvDelta: 0, rhrDelta: 0, workoutDelta: -30, stepsDelta: 0)
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 1.0)
        #expect(result.workout == 25.0)
        #expect(result.steps == 0.0)
    }

    @Test func stepsWeightIs15Points() {
        let trend = makeTrend(sleepDelta: 0, hrvDelta: 0, rhrDelta: 0, workoutDelta: 0, stepsDelta: -30)
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 1.0)
        #expect(result.steps == 15.0)
        #expect(result.workout == 0.0)
    }

    // MARK: - Edge cases

    @Test func scoreClampedAt0() {
        // Improvements should not go below 0
        let trend = makeTrend(sleepDelta: 50, hrvDelta: 50, rhrDelta: -50, workoutDelta: 50, stepsDelta: 50)
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 1.0)
        #expect(result.total >= 0)
    }

    @Test func scoreClampedAt100() {
        let trend = makeTrend()
        let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: 0.0)
        #expect(result.total <= 100)
    }
}
