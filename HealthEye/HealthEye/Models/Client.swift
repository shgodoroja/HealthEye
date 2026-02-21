import Foundation
import SwiftData

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var coach: CoachAccount?
    var displayName: String
    var timezone: String
    var status: ClientStatus
    var notes: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ClientImport.client)
    var imports: [ClientImport] = []

    @Relationship(deleteRule: .cascade, inverse: \MetricDaily.client)
    var metrics: [MetricDaily] = []

    @Relationship(deleteRule: .cascade, inverse: \AlertEvent.client)
    var alerts: [AlertEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \AttentionScore.client)
    var attentionScores: [AttentionScore] = []

    @Relationship(deleteRule: .cascade, inverse: \GeneratedReport.client)
    var reports: [GeneratedReport] = []

    @Relationship(deleteRule: .cascade, inverse: \MetricCompleteness.client)
    var completenessRecords: [MetricCompleteness] = []

    init(
        id: UUID = UUID(),
        coach: CoachAccount? = nil,
        displayName: String,
        timezone: String = TimeZone.current.identifier,
        status: ClientStatus = .active,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.coach = coach
        self.displayName = displayName
        self.timezone = timezone
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
    }
}
