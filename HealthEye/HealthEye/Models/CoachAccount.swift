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

    // Workspace preferences (set during S2 onboarding)
    var coachName: String
    var timezone: String
    var defaultReportDay: Int   // 1 = Monday … 7 = Sunday (ISO 8601 weekday)

    // Onboarding gate: false for brand-new accounts, true once S1+S2 are complete.
    // Defaults to true so existing accounts in the database skip onboarding.
    var onboardingCompleted: Bool

    @Relationship(deleteRule: .cascade, inverse: \Client.coach)
    var clients: [Client] = []

    init(
        id: UUID = UUID(),
        email: String,
        planType: PlanType = .trial,
        trialStartAt: Date? = nil,
        trialEndAt: Date? = nil,
        status: AccountStatus = .active,
        coachName: String = "",
        timezone: String = TimeZone.current.identifier,
        defaultReportDay: Int = 1,
        onboardingCompleted: Bool = true
    ) {
        self.id = id
        self.email = email
        self.planType = planType
        self.trialStartAt = trialStartAt
        self.trialEndAt = trialEndAt
        self.status = status
        self.coachName = coachName
        self.timezone = timezone
        self.defaultReportDay = defaultReportDay
        self.onboardingCompleted = onboardingCompleted
    }
}
