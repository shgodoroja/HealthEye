import SwiftUI

/// Manages the S1 → S2 onboarding flow in a single sheet.
struct OnboardingContainerView: View {
    let account: CoachAccount
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome

    private enum OnboardingStep {
        case welcome, workspaceSetup
    }

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView(account: account) {
                step = .workspaceSetup
            }
            .transition(.push(from: .trailing))
        case .workspaceSetup:
            WorkspaceSetupView(account: account) {
                onComplete()
            }
            .transition(.push(from: .trailing))
        }
    }
}
