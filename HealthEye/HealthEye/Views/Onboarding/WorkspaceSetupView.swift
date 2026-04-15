import SwiftUI
import SwiftData

struct WorkspaceSetupView: View {
    let account: CoachAccount
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var coachName: String = ""
    @State private var selectedTimezone: String = TimeZone.current.identifier
    @State private var selectedReportDay: Int = 1   // 1 = Monday

    private let reportDays: [(label: String, isoWeekday: Int)] = [
        ("Monday", 1),
        ("Tuesday", 2),
        ("Wednesday", 3),
        ("Thursday", 4),
        ("Friday", 5),
        ("Saturday", 6),
        ("Sunday", 7),
    ]

    private var groupedTimezones: [(region: String, identifiers: [String])] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        var grouped: [String: [String]] = [:]
        for id in all {
            let region = id.components(separatedBy: "/").first ?? "Other"
            grouped[region, default: []].append(id)
        }
        return grouped.keys.sorted().map { region in
            (region: region, identifiers: grouped[region]!)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)

                Text("Set up your workspace")
                    .font(.title)
                    .fontWeight(.bold)

                Text("These settings apply to every report you generate.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 36)

            Form {
                Section("Your name (optional)") {
                    TextField("e.g. Alex Rivera", text: $coachName)
                        .accessibilityIdentifier("workspace-coach-name-field")
                }

                Section("Timezone") {
                    Picker("Timezone", selection: $selectedTimezone) {
                        ForEach(groupedTimezones, id: \.region) { group in
                            Section(group.region) {
                                ForEach(group.identifiers, id: \.self) { id in
                                    Text(id.replacingOccurrences(of: "_", with: " "))
                                        .tag(id)
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("workspace-timezone-picker")
                }

                Section("Weekly report day") {
                    Picker("Report day", selection: $selectedReportDay) {
                        ForEach(reportDays, id: \.isoWeekday) { day in
                            Text(day.label).tag(day.isoWeekday)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("workspace-report-day-picker")

                    Text("Reports are generated for the 7-day window ending on this day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 480)

            Spacer(minLength: 24)

            Button(action: saveAndContinue) {
                Text("Continue to client setup")
                    .fontWeight(.semibold)
                    .frame(width: 280)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("workspace-continue-button")
        }
        .frame(minWidth: 540, minHeight: 520)
        .padding(40)
    }

    private func saveAndContinue() {
        account.coachName = coachName.trimmingCharacters(in: .whitespacesAndNewlines)
        account.timezone = selectedTimezone
        account.defaultReportDay = selectedReportDay
        account.onboardingCompleted = true

        AnalyticsService.track("workspace_config_saved", properties: [
            "timezone": selectedTimezone,
            "report_day": String(selectedReportDay),
        ])

        try? modelContext.save()
        onComplete()
    }
}
