import Foundation
import SwiftData

@Model
final class MetricDaily {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var date: Date
    var sleepMinutes: Double?
    var hrvMs: Double?
    var restingHrBpm: Double?
    var workoutMinutes: Double?
    var steps: Double?

    var completenessScore: Double {
        let fields: [Double?] = [sleepMinutes, hrvMs, restingHrBpm, workoutMinutes, steps]
        let nonNilCount = fields.compactMap({ $0 }).count
        return Double(nonNilCount) / 5.0
    }

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        date: Date,
        sleepMinutes: Double? = nil,
        hrvMs: Double? = nil,
        restingHrBpm: Double? = nil,
        workoutMinutes: Double? = nil,
        steps: Double? = nil
    ) {
        self.id = id
        self.client = client
        self.date = date
        self.sleepMinutes = sleepMinutes
        self.hrvMs = hrvMs
        self.restingHrBpm = restingHrBpm
        self.workoutMinutes = workoutMinutes
        self.steps = steps
    }
}
