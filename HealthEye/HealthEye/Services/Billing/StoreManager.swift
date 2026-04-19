import Foundation
import StoreKit

@MainActor @Observable
final class StoreManager {

    // MARK: - Published State

    private(set) var soloMonthlyProduct: Product?
    private(set) var soloAnnualProduct: Product?
    private(set) var proMonthlyProduct: Product?
    private(set) var proAnnualProduct: Product?

    private(set) var purchaseState: PurchaseState = .idle
    private(set) var currentEntitlement: PlanType = .trial
    private(set) var isEligibleForIntroOffer: Bool = true
    private(set) var productsLoaded: Bool = false

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case succeeded
        case failed(String)
    }

    enum BillingPeriod {
        case monthly
        case annual
    }

    // Back-compat shims so existing call sites/tests keep compiling.
    var soloProduct: Product? { soloMonthlyProduct }
    var proProduct: Product? { proMonthlyProduct }

    // MARK: - Product IDs

    static let soloMonthlyProductID = "sg.godoroja.Arclens.solo.monthly"
    static let soloAnnualProductID  = "sg.godoroja.Arclens.solo.annual"
    static let proMonthlyProductID  = "sg.godoroja.Arclens.pro.monthly"
    static let proAnnualProductID   = "sg.godoroja.Arclens.pro.annual"

    // Back-compat aliases
    static let soloProductID = soloMonthlyProductID
    static let proProductID  = proMonthlyProductID

    private static let allProductIDs: Set<String> = [
        soloMonthlyProductID,
        soloAnnualProductID,
        proMonthlyProductID,
        proAnnualProductID,
    ]

    // MARK: - Transaction Listener

    @ObservationIgnored private var updateListenerTask: Task<Void, Never>?

    init() {
        let isTestRun = ProcessInfo.processInfo.arguments.contains("-ui-testing")
            || (NSClassFromString("XCTestCase") != nil)
        guard !isTestRun else { return }
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.allProductIDs)
            for product in products {
                switch product.id {
                case Self.soloMonthlyProductID: soloMonthlyProduct = product
                case Self.soloAnnualProductID:  soloAnnualProduct  = product
                case Self.proMonthlyProductID:  proMonthlyProduct  = product
                case Self.proAnnualProductID:   proAnnualProduct   = product
                default: break
                }
            }
            productsLoaded = !products.isEmpty
            await refreshIntroOfferEligibility()
        } catch {
            // Products may not be available (e.g., no StoreKit config in scheme).
            // The paywall will show a "prices loading" state.
            productsLoaded = false
        }
    }

    // MARK: - Product Lookup

    func product(plan: PlanType, period: BillingPeriod) -> Product? {
        switch (plan, period) {
        case (.solo, .monthly): return soloMonthlyProduct
        case (.solo, .annual):  return soloAnnualProduct
        case (.pro,  .monthly): return proMonthlyProduct
        case (.pro,  .annual):  return proAnnualProduct
        default: return nil
        }
    }

    // MARK: - Intro Offer Eligibility

    /// Checks eligibility against the group's monthly product (intro offer is account-wide within a subscription group).
    func refreshIntroOfferEligibility() async {
        // Check against any product in the group; StoreKit treats the flag as group-level.
        let probe = soloMonthlyProduct ?? soloAnnualProduct ?? proMonthlyProduct ?? proAnnualProduct
        guard let probe, let subscription = probe.subscription else {
            isEligibleForIntroOffer = true
            return
        }
        let eligible = await subscription.isEligibleForIntroOffer
        isEligibleForIntroOffer = eligible
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlement()
                    await refreshIntroOfferEligibility()
                    purchaseState = .succeeded
                    let wasTrial = transaction.offerType == .introductory
                    AnalyticsService.track("upgrade_succeeded", properties: [
                        "plan": Self.planType(for: transaction.productID).rawValue,
                        "productID": transaction.productID,
                        "billing_period": Self.billingPeriod(for: transaction.productID).analyticsValue,
                        "used_intro_offer": wasTrial ? "true" : "false",
                    ])
                    if wasTrial {
                        AnalyticsService.track("trial_started", properties: [
                            "plan": Self.planType(for: transaction.productID).rawValue,
                            "productID": transaction.productID,
                        ])
                    }
                case .unverified(_, let error):
                    purchaseState = .failed("Purchase verification failed: \(error.localizedDescription)")
                    AnalyticsService.track("upgrade_failed", properties: [
                        "reason": "unverified",
                        "productID": product.id,
                    ])
                }
            case .userCancelled:
                purchaseState = .idle
                AnalyticsService.track("upgrade_cancelled", properties: [
                    "productID": product.id,
                ])
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            AnalyticsService.track("upgrade_failed", properties: [
                "reason": error.localizedDescription,
                "productID": product.id,
            ])
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            // sync may fail if the user is not signed in
        }
        await refreshEntitlement()
        AnalyticsService.track("restored", properties: [
            "result": currentEntitlement == .trial ? "no_subscription" : "restored",
            "plan": currentEntitlement.rawValue,
        ])
    }

    // MARK: - Entitlement Check

    /// Walks `Transaction.currentEntitlements`. Honors `revocationDate` (refunds / chargebacks) by
    /// skipping revoked transactions. Pro beats Solo when both are active (upgrade mid-period).
    func refreshEntitlement() async {
        var bestPlan: PlanType = .trial

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            // Refund / revocation: do not grant entitlement.
            if transaction.revocationDate != nil { continue }
            // Expired without renewal — skip (StoreKit still lists recently-expired sometimes).
            if let expiration = transaction.expirationDate, expiration < Date() { continue }

            let plan = Self.planType(for: transaction.productID)
            if plan == .pro {
                currentEntitlement = .pro
                return
            } else if plan == .solo {
                bestPlan = .solo
            }
        }

        currentEntitlement = bestPlan
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                    await self?.refreshIntroOfferEligibility()
                }
            }
        }
    }

    // MARK: - Helpers

    nonisolated static func planType(for productID: String) -> PlanType {
        switch productID {
        case soloMonthlyProductID, soloAnnualProductID: return .solo
        case proMonthlyProductID,  proAnnualProductID:  return .pro
        default: return .trial
        }
    }

    nonisolated static func billingPeriod(for productID: String) -> BillingPeriod {
        switch productID {
        case soloAnnualProductID, proAnnualProductID: return .annual
        default: return .monthly
        }
    }
}

extension StoreManager.BillingPeriod {
    var analyticsValue: String {
        switch self {
        case .monthly: return "monthly"
        case .annual:  return "annual"
        }
    }
}
