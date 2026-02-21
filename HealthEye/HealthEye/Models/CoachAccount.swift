import Foundation
import SwiftData

@Model
final class CoachAccount {
    @Attribute(.unique) var id: UUID
    var email: String
    var planType: PlanType
    var trialStartAt: Date?
    var trialEndAt: Date?
    var status: AccountStatus

    @Relationship(deleteRule: .cascade, inverse: \Client.coach)
    var clients: [Client] = []

    init(
        id: UUID = UUID(),
        email: String,
        planType: PlanType = .trial,
        trialStartAt: Date? = nil,
        trialEndAt: Date? = nil,
        status: AccountStatus = .active
    ) {
        self.id = id
        self.email = email
        self.planType = planType
        self.trialStartAt = trialStartAt
        self.trialEndAt = trialEndAt
        self.status = status
    }
}
