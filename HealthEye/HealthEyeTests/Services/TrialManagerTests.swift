import Testing
import Foundation
@testable import HealthEye

struct TrialManagerTests {

    private func makeAccount(
        planType: PlanType = .trial,
        trialStartAt: Date? = nil,
        trialEndAt: Date? = nil,
        status: AccountStatus = .active
    ) -> CoachAccount {
        CoachAccount(
            email: "coach@test.com",
            planType: planType,
            trialStartAt: trialStartAt,
            trialEndAt: trialEndAt,
            status: status
        )
    }

    // MARK: - Trial Expiration

    @Test func trialNotExpiredWithin14Days() {
        let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let account = makeAccount(trialStartAt: Date(), trialEndAt: trialEnd)

        #expect(!TrialManager.isTrialExpired(account: account))
    }

    @Test func trialExpiredAfter14Days() {
        let trialEnd = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let trialStart = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let account = makeAccount(trialStartAt: trialStart, trialEndAt: trialEnd)

        #expect(TrialManager.isTrialExpired(account: account))
    }

    @Test func trialDaysRemainingReturnsCorrectCount() {
        let trialEnd = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let account = makeAccount(trialStartAt: Date(), trialEndAt: trialEnd)

        let remaining = TrialManager.trialDaysRemaining(account: account)
        #expect(remaining >= 4 && remaining <= 5)
    }

    // MARK: - Report Gating

    @Test func paidPlanAllowsReports() {
        let account = makeAccount(planType: .solo)
        #expect(TrialManager.canGenerateReports(account: account))
    }

    @Test func expiredTrialBlocksReports() {
        let trialEnd = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let account = makeAccount(trialStartAt: Date(), trialEndAt: trialEnd)

        #expect(!TrialManager.canGenerateReports(account: account))
    }

    // MARK: - Client Limits

    @Test func clientLimitSoloIs30() {
        #expect(TrialManager.clientLimit(for: .solo) == 30)
    }

    @Test func clientLimitProIs100() {
        #expect(TrialManager.clientLimit(for: .pro) == 100)
    }

    // MARK: - Plan Selection

    @Test func selectPlanUpdatesAccount() {
        let account = makeAccount(
            trialStartAt: Date(),
            trialEndAt: Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        )

        TrialManager.selectPlan(.solo, account: account)

        #expect(account.planType == .solo)
        #expect(account.status == .active)
        #expect(account.trialStartAt == nil)
        #expect(account.trialEndAt == nil)
    }

    // MARK: - Entitlement Sync

    @Test func syncEntitlementUpgradesPlanAndClearsTrial() {
        let account = makeAccount(
            planType: .trial,
            trialStartAt: Date(),
            trialEndAt: Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        )

        let changed = TrialManager.syncEntitlement(.pro, to: account)

        #expect(changed)
        #expect(account.planType == .pro)
        #expect(account.trialStartAt == nil)
        #expect(account.trialEndAt == nil)
    }

    @Test func syncEntitlementDowngradesToTrialWhenSubscriptionEnds() {
        let account = makeAccount(planType: .solo)

        let changed = TrialManager.syncEntitlement(.trial, to: account)

        #expect(changed)
        #expect(account.planType == .trial)
    }
}
