import Foundation
import SwiftData

enum UITestScenario: String {
    case empty
    case expiredTrialWithClient = "expired_trial_with_client"
}

struct UITestBootstrapper {
    private static let scenarioKey = "UITEST_SCENARIO"
    private static var didBootstrap = false

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    @MainActor
    static func bootstrap(context: ModelContext) {
        guard isEnabled else { return }
        guard !didBootstrap else { return }
        didBootstrap = true

        clearExistingData(context: context)
        let scenario = scenario()

        switch scenario {
        case .empty:
            _ = TrialManager.ensureAccount(context: context)
        case .expiredTrialWithClient:
            seedExpiredTrialWithClient(context: context)
        }

        try? context.save()
    }

    private static func scenario() -> UITestScenario {
        guard
            let rawValue = ProcessInfo.processInfo.environment[scenarioKey],
            let scenario = UITestScenario(rawValue: rawValue)
        else {
            return .empty
        }

        return scenario
    }

    @MainActor
    private static func clearExistingData(context: ModelContext) {
        deleteAll(from: FetchDescriptor<GeneratedReport>(), context: context)
        deleteAll(from: FetchDescriptor<AlertEvent>(), context: context)
        deleteAll(from: FetchDescriptor<AttentionScore>(), context: context)
        deleteAll(from: FetchDescriptor<MetricCompleteness>(), context: context)
        deleteAll(from: FetchDescriptor<ClientImport>(), context: context)
        deleteAll(from: FetchDescriptor<MetricDaily>(), context: context)
        deleteAll(from: FetchDescriptor<Client>(), context: context)
        deleteAll(from: FetchDescriptor<CoachAccount>(), context: context)

        UserDefaults.standard.removeObject(forKey: "healtheye_analytics_events")
        try? context.save()
    }

    @MainActor
    private static func seedExpiredTrialWithClient(context: ModelContext) {
        let now = Date()
        let account = CoachAccount(
            email: "coach@example.com",
            planType: .trial,
            trialStartAt: Calendar.utc.date(byAdding: .day, value: -21, to: now),
            trialEndAt: Calendar.utc.date(byAdding: .day, value: -7, to: now),
            status: .expired
        )
        context.insert(account)

        let client = Client(
            coach: account,
            displayName: "Taylor Client",
            timezone: "UTC",
            notes: "UI test seed"
        )
        context.insert(client)

        for offset in stride(from: 35, through: 1, by: -1) {
            let date = Calendar.utc.date(byAdding: .day, value: -offset, to: now)!
            let isRecent = offset <= 7
            let metric = MetricDaily(
                client: client,
                date: Calendar.utc.startOfDay(for: date),
                sleepMinutes: isRecent ? 390 : 440,
                hrvMs: isRecent ? 42 : 55,
                restingHrBpm: isRecent ? 67 : 60,
                workoutMinutes: isRecent ? 15 : 35,
                steps: isRecent ? 5200 : 9000
            )
            context.insert(metric)
        }

        _ = try? ClientInsightsRefreshService.refresh(
            client: client,
            context: context,
            referenceDate: now
        )
    }

    @MainActor
    private static func deleteAll<Model: PersistentModel>(
        from descriptor: FetchDescriptor<Model>,
        context: ModelContext
    ) {
        guard let items = try? context.fetch(descriptor) else { return }
        for item in items {
            context.delete(item)
        }
    }
}

private extension Calendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
