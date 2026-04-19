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

    @Test func soloAnnualProductIDMapsToPlanTypeSolo() {
        #expect(StoreManager.planType(for: StoreManager.soloAnnualProductID) == .solo)
    }

    @Test func proAnnualProductIDMapsToPlanTypePro() {
        #expect(StoreManager.planType(for: StoreManager.proAnnualProductID) == .pro)
    }

    // MARK: - Billing Period Mapping

    @Test func soloMonthlyMapsToMonthly() {
        #expect(StoreManager.billingPeriod(for: StoreManager.soloMonthlyProductID) == .monthly)
    }

    @Test func proMonthlyMapsToMonthly() {
        #expect(StoreManager.billingPeriod(for: StoreManager.proMonthlyProductID) == .monthly)
    }

    @Test func soloAnnualMapsToAnnual() {
        #expect(StoreManager.billingPeriod(for: StoreManager.soloAnnualProductID) == .annual)
    }

    @Test func proAnnualMapsToAnnual() {
        #expect(StoreManager.billingPeriod(for: StoreManager.proAnnualProductID) == .annual)
    }

    // MARK: - Product ID Constants

    @Test func soloMonthlyProductIDFollowsConvention() {
        #expect(StoreManager.soloMonthlyProductID == "sg.godoroja.Arclens.solo.monthly")
    }

    @Test func proMonthlyProductIDFollowsConvention() {
        #expect(StoreManager.proMonthlyProductID == "sg.godoroja.Arclens.pro.monthly")
    }

    @Test func soloAnnualProductIDFollowsConvention() {
        #expect(StoreManager.soloAnnualProductID == "sg.godoroja.Arclens.solo.annual")
    }

    @Test func proAnnualProductIDFollowsConvention() {
        #expect(StoreManager.proAnnualProductID == "sg.godoroja.Arclens.pro.annual")
    }

    @Test func legacyAliasesStillResolve() {
        #expect(StoreManager.soloProductID == StoreManager.soloMonthlyProductID)
        #expect(StoreManager.proProductID == StoreManager.proMonthlyProductID)
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
