import Foundation
import SwiftData

@Model
final class AttentionScore {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var weekStart: Date
    var scoreTotal: Double
    var scoreSleep: Double
    var scoreHrv: Double
    var scoreRestingHr: Double
    var scoreWorkout: Double
    var scoreSteps: Double
    var scoreCompletenessPenalty: Double
    var scoreVersion: String
    var sourceDataHash: String
    var calculatedAt: Date

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        weekStart: Date,
        scoreTotal: Double = 0,
        scoreSleep: Double = 0,
        scoreHrv: Double = 0,
        scoreRestingHr: Double = 0,
        scoreWorkout: Double = 0,
        scoreSteps: Double = 0,
        scoreCompletenessPenalty: Double = 0,
        scoreVersion: String = "1.0",
        sourceDataHash: String = "",
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.client = client
        self.weekStart = weekStart
        self.scoreTotal = scoreTotal
        self.scoreSleep = scoreSleep
        self.scoreHrv = scoreHrv
        self.scoreRestingHr = scoreRestingHr
        self.scoreWorkout = scoreWorkout
        self.scoreSteps = scoreSteps
        self.scoreCompletenessPenalty = scoreCompletenessPenalty
        self.scoreVersion = scoreVersion
        self.sourceDataHash = sourceDataHash
        self.calculatedAt = calculatedAt
    }
}
