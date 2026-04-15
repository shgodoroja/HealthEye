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
            if isTestRun {
                fatalError("Could not create in-memory ModelContainer: \(error)")
            }
            // Persistent store migration failed (e.g. schema changed during
            // development). Reset the store and try once more rather than
            // crashing.
            if let storeURL = modelConfiguration.url {
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(
                    at: storeURL.appendingPathExtension("shm"))
                try? FileManager.default.removeItem(
                    at: storeURL.appendingPathExtension("wal"))
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
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
