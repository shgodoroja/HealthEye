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
        // Use in-memory store for any kind of test run so schema changes never
        // cause a migration failure that crashes the test host process.
        let isTestRun = UITestBootstrapper.isEnabled
            || (NSClassFromString("XCTestCase") != nil)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isTestRun)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Never delete the persistent store automatically. Health data is
            // user-owned; migration failures must preserve data for recovery.
            fatalError("""
            Could not create ModelContainer: \(error)
            Persistent store was left untouched at \(modelConfiguration.url.path).
            Recover by backing up/exporting that store before applying a migration fix.
            """)
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
