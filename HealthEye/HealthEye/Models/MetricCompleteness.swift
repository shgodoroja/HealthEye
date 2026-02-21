import Foundation
import SwiftData

@Model
final class MetricCompleteness {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var weekStart: Date
    var hasSleep: Bool
    var hasHrv: Bool
    var hasRestingHr: Bool
    var hasWorkout: Bool
    var hasSteps: Bool
    var completenessScore: Double
    var notes: String?

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        weekStart: Date,
        hasSleep: Bool = false,
        hasHrv: Bool = false,
        hasRestingHr: Bool = false,
        hasWorkout: Bool = false,
        hasSteps: Bool = false,
        completenessScore: Double = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.client = client
        self.weekStart = weekStart
        self.hasSleep = hasSleep
        self.hasHrv = hasHrv
        self.hasRestingHr = hasRestingHr
        self.hasWorkout = hasWorkout
        self.hasSteps = hasSteps
        self.completenessScore = completenessScore
        self.notes = notes
    }
}
