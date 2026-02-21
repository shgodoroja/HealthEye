import Foundation
import SwiftData

@Model
final class AlertEvent {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var weekStart: Date
    var ruleCode: String
    var severity: AlertSeverity
    var explanationText: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        weekStart: Date,
        ruleCode: String,
        severity: AlertSeverity,
        explanationText: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.client = client
        self.weekStart = weekStart
        self.ruleCode = ruleCode
        self.severity = severity
        self.explanationText = explanationText
        self.createdAt = createdAt
    }
}
