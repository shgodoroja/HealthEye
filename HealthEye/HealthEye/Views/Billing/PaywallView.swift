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
    var surface: String = "menu"

    @State private var billingPeriod: StoreManager.BillingPeriod = .annual
    @State private var restoreMessage: String?
    @State private var manageSubscriptionsPresented = false

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

    private var showIntroOfferCopy: Bool {
        storeManager.isEligibleForIntroOffer && effectivePlan == .trial
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 18) {
                    heroBlock
                    trialBanner
                    restoreBanner
                    errorBanner
                    billingToggle
                    planCards
                    secondaryActions
                    legalFooter
                }
                .padding(.vertical, 20)
            }
        }
        .frame(minWidth: 640, minHeight: 560)
        .onAppear {
            AnalyticsService.track("paywall_viewed", account: account, extra: [
                "surface": surface,
                "effective_plan": effectivePlan.rawValue,
            ])
            Task {
                await storeManager.loadProducts()
                await storeManager.refreshEntitlement()
                await storeManager.refreshIntroOfferEligibility()
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
                AnalyticsService.track("plan_selected", account: account, extra: [
                    "plan": newEntitlement.rawValue,
                    "surface": surface,
                ])
                dismiss()
            }
        }
        #if !os(macOS)
        .manageSubscriptionsSheet(isPresented: $manageSubscriptionsPresented)
        #endif
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Plans & Billing")
                .font(.headline)
                .accessibilityIdentifier("paywall-title")
            Spacer()
            Button("Close") { dismiss() }
                .accessibilityIdentifier("paywall-close")
                .keyboardShortcut(.cancelAction)
        }
        .padding()
        .background(.background)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spot at-risk clients before Monday")
                .font(.title2.weight(.semibold))
            Text("Weekly Apple Health triage, explainable scoring, and one-click coach reports.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Billing period toggle

    private var billingToggle: some View {
        HStack(spacing: 0) {
            toggleChip(title: "Monthly", period: .monthly)
            toggleChip(title: "Annual  ·  Save ~17%", period: .annual)
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: 360)
        .padding(.horizontal)
        .accessibilityIdentifier("paywall-billing-toggle")
    }

    private func toggleChip(title: String, period: StoreManager.BillingPeriod) -> some View {
        Button {
            billingPeriod = period
            AnalyticsService.track("paywall_billing_toggled", account: account, extra: [
                "period": period.analyticsValue,
            ])
        } label: {
            Text(title)
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(billingPeriod == period ? Color.accentColor.opacity(0.18) : Color.clear)
                )
                .foregroundStyle(billingPeriod == period ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("paywall-period-\(period.analyticsValue)")
    }

    // MARK: - Plan cards

    private var planCards: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 16) {
            planCard(name: "Solo", plan: .solo, highlighted: false)
            planCard(name: "Pro",  plan: .pro,  highlighted: true)
        }
        .padding(.horizontal)
        #else
        Group {
            if dynamicCompactLayout {
                VStack(spacing: 16) {
                    planCard(name: "Pro",  plan: .pro,  highlighted: true)
                    planCard(name: "Solo", plan: .solo, highlighted: false)
                }
                .padding(.horizontal)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    planCard(name: "Solo", plan: .solo, highlighted: false)
                    planCard(name: "Pro",  plan: .pro,  highlighted: true)
                }
                .padding(.horizontal)
            }
        }
        #endif
    }

    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var dynamicCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
    #endif

    // MARK: - Secondary actions

    private var secondaryActions: some View {
        VStack(spacing: 10) {
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
            .secondaryLinkStyle()
            .accessibilityIdentifier("paywall-restore")

            Button("Manage Subscription") {
                openManageSubscriptions()
            }
            .secondaryLinkStyle()
            .accessibilityIdentifier("paywall-manage-subscription")
        }
        .padding(.top, 4)
    }

    // MARK: - Legal footer (Apple 3.1.2 disclosures)

    private var legalFooter: some View {
        VStack(spacing: 8) {
            Text("Payment is charged to your Apple ID after the 14-day free trial. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in System Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityIdentifier("paywall-autorenew-disclosure")

            HStack(spacing: 14) {
                Link("Terms of Use", destination: URL(string: "https://healtheye.app/terms/")!)
                    .accessibilityIdentifier("paywall-terms")
                Link("Privacy Policy", destination: URL(string: "https://healtheye.app/privacy/")!)
                    .accessibilityIdentifier("paywall-privacy")
            }
            .font(.caption)
        }
        .padding(.top, 6)
    }

    // MARK: - Banners

    @ViewBuilder
    private var trialBanner: some View {
        switch viewState {
        case .trialActive(let daysLeft):
            banner(
                icon: "clock",
                tint: .orange,
                text: "\(daysLeft) day\(daysLeft == 1 ? "" : "s") remaining in your free trial"
            )
        case .trialExpired:
            banner(
                icon: "exclamationmark.triangle.fill",
                tint: .red,
                text: "Your trial has expired. Choose a plan to continue.",
                identifier: "paywall-expired-banner"
            )
        case .subscribed(let plan):
            banner(
                icon: "checkmark.seal.fill",
                tint: .green,
                text: "You are on the \(plan.rawValue.capitalized) plan"
            )
        }
    }

    @ViewBuilder
    private var restoreBanner: some View {
        if let restoreMessage {
            banner(icon: "info.circle.fill", tint: .blue, text: restoreMessage)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if case .failed(let message) = storeManager.purchaseState {
            banner(icon: "xmark.circle.fill", tint: .red, text: message)
        }
    }

    private func banner(icon: String, tint: Color, text: String, identifier: String? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(3)
                .accessibilityIdentifier(identifier ?? "")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }

    // MARK: - Plan Card

    private func planCard(name: String, plan: PlanType, highlighted: Bool) -> some View {
        let product = storeManager.product(plan: plan, period: billingPeriod)
        let monthlyEquivalent = monthlyEquivalentCopy(product: product, period: billingPeriod)
        let perClientCopy = perClientMath(plan: plan, period: billingPeriod, product: product)
        let features = features(for: plan)
        let clientLimit = clientLimit(for: plan)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if highlighted {
                    Text("Most Popular")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("paywall-most-popular")
                }
            }

            priceBlock(product: product, monthlyEquivalent: monthlyEquivalent)

            if let perClientCopy {
                Text(perClientCopy)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Text(clientLimit)
                .font(.callout)
                .fontWeight(.medium)

            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text(feature)
                        .font(.callout)
                }
            }

            Spacer(minLength: 4)

            cta(plan: plan, name: name, product: product)

            if showIntroOfferCopy, product != nil {
                Text("No charge today. Cancel anytime in System Settings.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(highlighted ? Color.accentColor : Color.secondary.opacity(0.3),
                        lineWidth: highlighted ? 2 : 1)
        )
    }

    private func priceBlock(product: Product?, monthlyEquivalent: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let product {
                Text(product.displayPrice)
                    .font(.title3.weight(.semibold))
                Text(billingPeriod == .annual ? "per year" : "per month")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if let monthlyEquivalent {
                    Text(monthlyEquivalent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if storeManager.productsLoaded {
                // Products loaded but this specific SKU missing — rare; show dash.
                Text("—")
                    .font(.title3.weight(.semibold))
                Text("Price unavailable")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Loading price…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("paywall-price-loading")
            }
        }
    }

    @ViewBuilder
    private func cta(plan: PlanType, name: String, product: Product?) -> some View {
        if effectivePlan == plan {
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
                AnalyticsService.track("paywall_cta_tapped", account: account, extra: [
                    "plan": plan.rawValue,
                    "billing_period": billingPeriod.analyticsValue,
                    "surface": surface,
                    "intro_eligible": storeManager.isEligibleForIntroOffer ? "true" : "false",
                ])
                Task { await storeManager.purchase(product) }
            } label: {
                if storeManager.purchaseState == .purchasing {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(ctaLabel(for: name, product: product))
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(product == nil || storeManager.purchaseState == .purchasing)
            .keyboardShortcut(plan == .pro ? .defaultAction : nil)
            .accessibilityIdentifier("paywall-choose-\(plan.rawValue)")
        }
    }

    private func ctaLabel(for name: String, product: Product?) -> String {
        guard product != nil else { return "Unavailable" }
        if showIntroOfferCopy {
            return "Start 14-day free trial"
        }
        return "Choose \(name)"
    }

    // MARK: - Copy helpers

    private func monthlyEquivalentCopy(product: Product?, period: StoreManager.BillingPeriod) -> String? {
        guard period == .annual, let product else { return nil }
        let monthly = NSDecimalNumber(decimal: product.price)
            .dividing(by: NSDecimalNumber(value: 12))
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        formatter.maximumFractionDigits = 2
        guard let formatted = formatter.string(from: monthly) else { return nil }
        return "≈ \(formatted)/mo, billed annually"
    }

    private func perClientMath(plan: PlanType, period: StoreManager.BillingPeriod, product: Product?) -> String? {
        guard let product else { return nil }
        let monthlyPrice: Decimal
        switch period {
        case .monthly: monthlyPrice = product.price
        case .annual:  monthlyPrice = product.price / 12
        }
        let clients: Decimal = plan == .pro ? 100 : 30
        let weekly = monthlyPrice / (clients * 4)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        guard let weeklyString = formatter.string(from: NSDecimalNumber(decimal: weekly)) else { return nil }
        return "≈ \(weeklyString) per client per week at \(clients) clients"
    }

    private func features(for plan: PlanType) -> [String] {
        switch plan {
        case .solo:
            return [
                "Weekly client triage dashboard",
                "Explainable attention scoring",
                "One-click PDF reports",
                "CSV & JSON data export",
            ]
        case .pro:
            return [
                "Everything in Solo",
                "Bulk weekly report generation",
                "Priority email support",
                "Custom report branding",
            ]
        case .trial:
            return []
        }
    }

    private func clientLimit(for plan: PlanType) -> String {
        switch plan {
        case .solo:  return "Up to 30 active clients"
        case .pro:   return "Up to 100 active clients"
        case .trial: return ""
        }
    }

    private enum PaywallState {
        case trialActive(daysLeft: Int)
        case trialExpired
        case subscribed(PlanType)
    }

    @MainActor
    private func openManageSubscriptions() {
        AnalyticsService.track("manage_subscription_opened", account: account)
        #if os(macOS)
        let url = URL(string: "https://apps.apple.com/account/subscriptions")!
        NSWorkspace.shared.open(url)
        #else
        manageSubscriptionsPresented = true
        #endif
    }
}

// MARK: - Style helper

private extension View {
    @ViewBuilder
    func secondaryLinkStyle() -> some View {
        #if os(macOS)
        self.buttonStyle(.link).font(.callout)
        #else
        self.buttonStyle(.plain).foregroundStyle(.tint).font(.callout)
        #endif
    }
}
