import Foundation
import StoreKit

@MainActor @Observable
final class StoreManager {

    // MARK: - Published State

    private(set) var soloProduct: Product?
    private(set) var proProduct: Product?
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var currentEntitlement: PlanType = .trial

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case succeeded
        case failed(String)
    }

    // MARK: - Product IDs

    static let soloProductID = "sg.godoroja.HealthEye.solo.monthly"
    static let proProductID  = "sg.godoroja.HealthEye.pro.monthly"
    private static let allProductIDs: Set<String> = [soloProductID, proProductID]

    // MARK: - Transaction Listener

    nonisolated(unsafe) private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
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
                case Self.soloProductID:
                    soloProduct = product
                case Self.proProductID:
                    proProduct = product
                default:
                    break
                }
            }
        } catch {
            // Products may not be available (e.g., no StoreKit config in scheme).
            // The paywall will show fallback prices.
        }
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
                    purchaseState = .succeeded
                    AnalyticsService.track("upgrade_succeeded", properties: [
                        "plan": Self.planType(for: transaction.productID).rawValue,
                        "productID": transaction.productID,
                    ])
                case .unverified(_, let error):
                    purchaseState = .failed("Purchase verification failed: \(error.localizedDescription)")
                    AnalyticsService.track("upgrade_failed", properties: [
                        "reason": "unverified",
                        "productID": product.id,
                    ])
                }
            case .userCancelled:
                purchaseState = .idle
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
    }

    // MARK: - Entitlement Check

    func refreshEntitlement() async {
        var bestPlan: PlanType = .trial

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                let plan = Self.planType(for: transaction.productID)
                if plan == .pro {
                    currentEntitlement = .pro
                    return
                } else if plan == .solo {
                    bestPlan = .solo
                }
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
                }
            }
        }
    }

    // MARK: - Helpers

    nonisolated static func planType(for productID: String) -> PlanType {
        switch productID {
        case soloProductID: return .solo
        case proProductID: return .pro
        default: return .trial
        }
    }
}
