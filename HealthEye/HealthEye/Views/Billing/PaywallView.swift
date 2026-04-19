import SwiftUI
import SwiftData
import StoreKit
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct PaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    let account: CoachAccount
    @State private var restoreMessage: String?

    private var effectivePlan: PlanType {
        if storeManager.currentEntitlement == .pro || account.planType == .pro {
            return .pro
        }
        if storeManager.currentEntitlement == .solo || account.planType == .solo {
            return .solo
        }
        return .trial
    }

    private var viewState: PaywallState {
        switch effectivePlan {
        case .trial:
            if TrialManager.isTrialExpired(account: account) {
                return .trialExpired
            }
            return .trialActive(daysLeft: TrialManager.trialDaysRemaining(account: account))
        case .solo:
            return .subscribed(.solo)
        case .pro:
            return .subscribed(.pro)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Plans & Billing")
                    .font(.headline)
                    .accessibilityIdentifier("paywall-title")
                Spacer()
                Button("Close") { dismiss() }
                    .accessibilityIdentifier("paywall-close")
            }
            .padding()
            .background(.background)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    trialBanner

                    restoreBanner

                    errorBanner

                    HStack(spacing: 16) {
                        planCard(
                            name: "Solo",
                            product: storeManager.soloProduct,
                            fallbackPrice: "$39.99/mo",
                            clientLimit: "Up to 30 clients",
                            features: ["Weekly reports", "Alert engine", "CSV/JSON export"],
                            planType: .solo,
                            highlighted: false
                        )

                        planCard(
                            name: "Pro",
                            product: storeManager.proProduct,
                            fallbackPrice: "$79.99/mo",
                            clientLimit: "Up to 100 clients",
                            features: ["Everything in Solo", "Priority support", "Custom branding"],
                            planType: .pro,
                            highlighted: true
                        )
                    }
                    .padding(.horizontal)

                    Button("Restore Purchases") {
                        Task {
                            await storeManager.restorePurchases()
                            _ = TrialManager.syncEntitlement(
                                from: storeManager,
                                to: account,
                                context: modelContext
                            )
                            if storeManager.currentEntitlement == .trial {
                                restoreMessage = "No active subscriptions were found for this Apple ID."
                            } else {
                                restoreMessage = "Purchases restored successfully."
                            }
                        }
                    }
                    #if os(macOS)
                    .buttonStyle(.link)
                    #else
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    #endif
                    .font(.callout)
                    .padding(.bottom, 8)

                    Button("Manage Subscription") {
                        openManageSubscriptions()
                    }
                    #if os(macOS)
                    .buttonStyle(.link)
                    #else
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    #endif
                    .font(.callout)
                    .accessibilityIdentifier("paywall-manage-subscription")
                }
                .padding(.vertical, 24)
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .onAppear {
            AnalyticsService.track("paywall_viewed", account: account)
            Task {
                await storeManager.loadProducts()
                await storeManager.refreshEntitlement()
                _ = TrialManager.syncEntitlement(
                    from: storeManager,
                    to: account,
                    context: modelContext
                )
            }
        }
        .onChange(of: storeManager.currentEntitlement) { _, newEntitlement in
            if newEntitlement != .trial {
                _ = TrialManager.syncEntitlement(
                    from: storeManager,
                    to: account,
                    context: modelContext
                )
                AnalyticsService.track("plan_selected", account: account, extra: ["plan": newEntitlement.rawValue])
                dismiss()
            }
        }
    }

    // MARK: - Trial Banner

    @ViewBuilder
    private var trialBanner: some View {
        switch viewState {
        case .trialActive(let daysLeft):
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
                Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s") remaining in your free trial")
                    .font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

        case .trialExpired:
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Your trial has expired. Choose a plan to continue.")
                    .font(.callout)
                    .fontWeight(.medium)
                    .accessibilityIdentifier("paywall-expired-banner")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

        case .subscribed(let plan):
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("You are on the \(plan.rawValue.capitalized) plan")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var restoreBanner: some View {
        if let restoreMessage {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text(restoreMessage)
                    .font(.callout)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if case .failed(let message) = storeManager.purchaseState {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.callout)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
        }
    }

    // MARK: - Plan Card

    private func planCard(
        name: String,
        product: Product?,
        fallbackPrice: String,
        clientLimit: String,
        features: [String],
        planType: PlanType,
        highlighted: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.title2)
                .fontWeight(.bold)

            Text(product?.displayPrice ?? fallbackPrice)
                .font(.title3)
                .foregroundStyle(.secondary)

            if product != nil {
                Text("per month")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Text(clientLimit)
                .font(.callout)
                .fontWeight(.medium)

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text(feature)
                        .font(.callout)
                }
            }

            Spacer()

            if effectivePlan == planType {
                Text("Current Plan")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Button {
                    guard let product else { return }
                    Task {
                        await storeManager.purchase(product)
                    }
                } label: {
                    if storeManager.purchaseState == .purchasing {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Choose \(name)")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(product == nil || storeManager.purchaseState == .purchasing)
                .accessibilityIdentifier("paywall-choose-\(planType.rawValue)")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(highlighted ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: highlighted ? 2 : 1)
        )
    }

    private enum PaywallState {
        case trialActive(daysLeft: Int)
        case trialExpired
        case subscribed(PlanType)
    }

    @MainActor
    private func openManageSubscriptions() {
        let url = URL(string: "https://apps.apple.com/account/subscriptions")!
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}
