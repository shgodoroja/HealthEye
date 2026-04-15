import SwiftUI
import SwiftData

@main
struct HealthEyeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CoachAccount.self,
            Client.self,
            ClientImport.self,
            MetricDaily.self,
            AlertEvent.self,
            AttentionScore.self,
            GeneratedReport.self,
            MetricCompleteness.self,
        ])
        let isUITesting = UITestBootstrapper.isEnabled
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    if UITestBootstrapper.isEnabled {
                        UITestBootstrapper.bootstrap(context: context)
                    } else {
                        TrialManager.ensureAccount(context: context)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
