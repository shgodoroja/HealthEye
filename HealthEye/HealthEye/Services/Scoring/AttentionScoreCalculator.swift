import Foundation
import CryptoKit
import SwiftData

struct AttentionScoreResult: Sendable {
    let total: Double
    let recoverySleep: Double
    let recoveryHrv: Double
    let recoveryRestingHr: Double
    let workout: Double
    let steps: Double
    let completenessPenalty: Double
    let bucket: AttentionBucket
    let sourceDataHash: String
}

struct AttentionScoreCalculator {

    // Weight constants
    private static let recoveryWeight: Double = 45.0
    private static let workoutWeight: Double = 25.0
    private static let stepsWeight: Double = 15.0
    private static let completenessWeight: Double = 15.0

    // Recovery sub-weights (within the 45% recovery bucket)
    private static let hrvSubWeight: Double = 0.40
    private static let rhrSubWeight: Double = 0.30
    private static let sleepSubWeight: Double = 0.30

    /// Computes attention score from metric trend and completeness.
    /// Higher score = needs MORE attention (worse trends).
    static func calculate(
        trend: MetricTrend,
        completenessScore: Double
    ) -> AttentionScoreResult {
        // Recovery component (45 points max)
        let hrvScore = deviationScore(delta: trend.hrvDelta, invert: true)
        let rhrScore = deviationScore(delta: trend.restingHrDelta, invert: false)
        let sleepScore = deviationScore(delta: trend.sleepDelta, invert: true)

        let recoveryHrvPoints = hrvScore * recoveryWeight * hrvSubWeight
        let recoveryRhrPoints = rhrScore * recoveryWeight * rhrSubWeight
        let recoverySleepPoints = sleepScore * recoveryWeight * sleepSubWeight

        // Workout component (25 points max)
        let workoutScore = deviationScore(delta: trend.workoutDelta, invert: true)
        let workoutPoints = workoutScore * workoutWeight

        // Steps component (15 points max)
        let stepsScore = deviationScore(delta: trend.stepsDelta, invert: true)
        let stepsPoints = stepsScore * stepsWeight

        // Completeness penalty (15 points max)
        let completenessPoints = (1.0 - completenessScore) * completenessWeight

        let total = min(100, max(0,
            recoveryHrvPoints + recoveryRhrPoints + recoverySleepPoints +
            workoutPoints + stepsPoints + completenessPoints
        ))

        let hash = computeSourceHash(trend: trend, completenessScore: completenessScore)

        return AttentionScoreResult(
            total: total,
            recoverySleep: recoverySleepPoints,
            recoveryHrv: recoveryHrvPoints,
            recoveryRestingHr: recoveryRhrPoints,
            workout: workoutPoints,
            steps: stepsPoints,
            completenessPenalty: completenessPoints,
            bucket: AttentionBucket.from(score: total),
            sourceDataHash: hash
        )
    }

    /// Maps a percentage delta to a 0-1 deviation score.
    /// - `invert: true` means negative delta = worse (HRV, Sleep, Workout, Steps dropping is bad)
    /// - `invert: false` means positive delta = worse (RHR rising is bad)
    /// Missing data (nil delta) returns 0.0 and is handled by completeness separately.
    private static func deviationScore(delta: Double?, invert: Bool) -> Double {
        guard let delta = delta else { return 0.0 }

        let relevantDelta = invert ? -delta : delta

        // Scale: 0% change = 0.0 score, >= 30% negative change = 1.0 score
        // Linear scaling clamped to [0, 1]
        let score = max(0, min(1.0, relevantDelta / 30.0))
        return score
    }

    private static func computeSourceHash(trend: MetricTrend, completenessScore: Double) -> String {
        var values: [String] = []

        // Sort by key for determinism
        let pairs: [(String, Double?)] = [
            ("completeness", completenessScore),
            ("hrv_delta", trend.hrvDelta),
            ("rhr_delta", trend.restingHrDelta),
            ("sleep_delta", trend.sleepDelta),
            ("steps_delta", trend.stepsDelta),
            ("workout_delta", trend.workoutDelta),
        ]

        for (key, value) in pairs {
            if let v = value {
                values.append("\(key):\(v)")
            } else {
                values.append("\(key):nil")
            }
        }

        let input = values.joined(separator: "|")
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Persists attention score result to the database.
    @MainActor
    static func saveScore(
        result: AttentionScoreResult,
        client: Client,
        weekStart: Date,
        context: ModelContext
    ) throws {
        let clientID = client.id
        let descriptor = FetchDescriptor<AttentionScore>(
            predicate: #Predicate<AttentionScore> { score in
                score.client?.id == clientID && score.weekStart == weekStart
            }
        )
        let existing = try context.fetch(descriptor).first

        let record: AttentionScore
        if let existing {
            record = existing
        } else {
            record = AttentionScore(client: client, weekStart: weekStart)
            context.insert(record)
        }

        record.scoreTotal = result.total
        record.scoreSleep = result.recoverySleep
        record.scoreHrv = result.recoveryHrv
        record.scoreRestingHr = result.recoveryRestingHr
        record.scoreWorkout = result.workout
        record.scoreSteps = result.steps
        record.scoreCompletenessPenalty = result.completenessPenalty
        record.sourceDataHash = result.sourceDataHash
        record.calculatedAt = Date()
    }
}
