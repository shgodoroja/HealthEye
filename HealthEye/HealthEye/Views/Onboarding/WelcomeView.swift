import SwiftUI
import SwiftData

struct WelcomeView: View {
    let account: CoachAccount
    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var email: String = ""
    @State private var emailError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero
            VStack(spacing: 16) {
                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("Welcome to Arclens")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Turn Apple Watch data into actionable weekly coaching insights for every client.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .padding(.bottom, 48)

            // Email form
            VStack(alignment: .leading, spacing: 8) {
                Text("Your email")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("coach@example.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)
                    .onSubmit(attemptContinue)

                if let error = emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.bottom, 8)

            // Persona note (Coach is the only persona in MVP)
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("You're signing up as a **Coach** — the account type for managing multiple clients.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 360, alignment: .leading)
            .padding(.bottom, 32)

            // CTA
            Button(action: attemptContinue) {
                Text("Start 14-day free trial")
                    .fontWeight(.semibold)
                    .frame(width: 280)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("No credit card required. Cancel anytime.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 10)

            Spacer()
        }
        .frame(minWidth: 540, minHeight: 480)
        .padding(40)
    }

    private static let emailRegex = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/

    private func attemptContinue() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (try? Self.emailRegex.wholeMatch(in: trimmed)) != nil else {
            emailError = "Enter a valid email address."
            return
        }
        emailError = nil

        let now = Date()
        let trialEnd = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        account.email = trimmed
        account.trialStartAt = now
        account.trialEndAt = trialEnd

        AnalyticsService.track("trial_started", properties: ["email": trimmed])
        AnalyticsService.track("persona_selected", properties: ["persona": "coach"])

        try? modelContext.save()
        onContinue()
    }
}
