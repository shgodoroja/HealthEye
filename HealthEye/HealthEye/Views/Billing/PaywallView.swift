import SwiftUI
import SwiftData

struct PaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: CoachAccount

    private var viewState: PaywallState {
        switch account.planType {
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
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    trialBanner

                    HStack(spacing: 16) {
                        planCard(
                            name: "Solo",
                            price: "$39/mo",
                            clientLimit: "Up to 30 clients",
                            features: ["Weekly reports", "Alert engine", "CSV/JSON export"],
                            planType: .solo,
                            highlighted: false
                        )

                        planCard(
                            name: "Pro",
                            price: "$79/mo",
                            clientLimit: "Up to 100 clients",
                            features: ["Everything in Solo", "Priority support", "Custom branding"],
                            planType: .pro,
                            highlighted: true
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .onAppear {
            AnalyticsService.track("paywall_viewed")
        }
    }

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

    private func planCard(
        name: String,
        price: String,
        clientLimit: String,
        features: [String],
        planType: PlanType,
        highlighted: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.title2)
                .fontWeight(.bold)

            Text(price)
                .font(.title3)
                .foregroundStyle(.secondary)

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

            if account.planType == planType {
                Text("Current Plan")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Button("Choose \(name)") {
                    TrialManager.selectPlan(planType, account: account)
                    AnalyticsService.track("plan_selected", properties: ["plan": planType.rawValue])
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
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
}
