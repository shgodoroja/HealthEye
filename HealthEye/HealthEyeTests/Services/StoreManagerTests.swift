import Testing
import Foundation
@testable import HealthEye

struct StoreManagerTests {

    // MARK: - Product ID to PlanType Mapping (nonisolated, no @MainActor needed)

    @Test func soloProductIDMapsToPlanTypeSolo() {
        #expect(StoreManager.planType(for: StoreManager.soloProductID) == .solo)
    }

    @Test func proProductIDMapsToPlanTypePro() {
        #expect(StoreManager.planType(for: StoreManager.proProductID) == .pro)
    }

    @Test func unknownProductIDMapsToPlanTypeTrial() {
        #expect(StoreManager.planType(for: "com.example.unknown") == .trial)
    }

    // MARK: - Product ID Constants

    @Test func soloProductIDFollowsConvention() {
        #expect(StoreManager.soloProductID == "sg.godoroja.Arclens.solo.monthly")
    }

    @Test func proProductIDFollowsConvention() {
        #expect(StoreManager.proProductID == "sg.godoroja.Arclens.pro.monthly")
    }

    // MARK: - Sync Entitlement via TrialManager

    @Test func selectPlanUpgradesToSolo() {
        let account = CoachAccount(email: "test@test.com", planType: .trial)
        TrialManager.selectPlan(.solo, account: account)
        #expect(account.planType == .solo)
        #expect(account.trialStartAt == nil)
        #expect(account.trialEndAt == nil)
    }

    @Test func selectPlanUpgradesToPro() {
        let account = CoachAccount(email: "test@test.com", planType: .solo)
        TrialManager.selectPlan(.pro, account: account)
        #expect(account.planType == .pro)
    }

    // MARK: - Initial State

    @MainActor @Test func initialPurchaseStateIsIdle() {
        let manager = StoreManager()
        #expect(manager.purchaseState == .idle)
    }

    @MainActor @Test func initialEntitlementIsTrial() {
        let manager = StoreManager()
        #expect(manager.currentEntitlement == .trial)
    }
}
