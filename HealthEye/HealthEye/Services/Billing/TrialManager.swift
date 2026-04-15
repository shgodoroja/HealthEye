import Foundation
import SwiftData

struct TrialManager {

    private static let trialDurationDays = 14

    // MARK: - Trial Lifecycle

    static func trialDaysRemaining(account: CoachAccount) -> Int {
        guard let trialEndAt = account.trialEndAt else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()),
                                           to: calendar.startOfDay(for: trialEndAt)).day ?? 0
        return max(days, 0)
    }

    static func isTrialExpired(account: CoachAccount) -> Bool {
        guard account.planType == .trial else { return false }
        guard let trialEndAt = account.trialEndAt else { return true }
        return Date() > trialEndAt
    }

    // MARK: - Feature Gating

    static func canGenerateReports(account: CoachAccount) -> Bool {
        switch account.planType {
        case .solo, .pro:
            return true
        case .trial:
            return !isTrialExpired(account: account)
        }
    }

    static func canAddClient(account: CoachAccount, currentActiveCount: Int) -> Bool {
        let limit = clientLimit(for: account.planType)
        return currentActiveCount < limit
    }

    static func clientLimit(for planType: PlanType) -> Int {
        switch planType {
        case .trial, .solo:
            return 30
        case .pro:
            return 100
        }
    }

    // MARK: - Plan Selection (Stub)

    static func selectPlan(_ plan: PlanType, account: CoachAccount) {
        account.planType = plan
        account.status = .active
        if plan != .trial {
            account.trialStartAt = nil
            account.trialEndAt = nil
        }
    }

    // MARK: - Account Bootstrap

    @discardableResult
    static func ensureAccount(context: ModelContext) -> CoachAccount {
        let descriptor = FetchDescriptor<CoachAccount>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        // Trial timestamps are set when the user completes S1 onboarding.
        // New accounts start with onboardingCompleted = false so the welcome
        // flow is shown before the main workspace.
        let account = CoachAccount(
            email: "",
            planType: .trial,
            status: .active,
            onboardingCompleted: false
        )
        context.insert(account)
        return account
    }
}
