import SwiftUI
import SwiftData

@main
struct ArclensApp: App {
    @State private var storeManager = StoreManager()

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

        let modelConfiguration: ModelConfiguration
        if isTestRun {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            // Store in a file-protected directory (NFR-003: encrypted at rest).
            let storeURL = StoreEncryption.prepareStoreURL()
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        }

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            if !isTestRun {
                StoreEncryption.verifyEncryptionEnvironment()
            }

            return container
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
                .environment(storeManager)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    // Ensure the main window is visible, especially during UI tests
                    // launched from xcodebuild CLI.
                    #if os(macOS)
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        for window in NSApplication.shared.windows {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                    #endif
                    let context = sharedModelContainer.mainContext
                    if UITestBootstrapper.isEnabled {
                        UITestBootstrapper.bootstrap(context: context)
                    } else {
                        TrialManager.ensureAccount(context: context)
                    }
                }
                .task {
                    let isTestRun = UITestBootstrapper.isEnabled
                        || (NSClassFromString("XCTestCase") != nil)
                    guard !isTestRun else { return }

                    await storeManager.refreshEntitlement()
                    let context = sharedModelContainer.mainContext
                    let descriptor = FetchDescriptor<CoachAccount>()
                    guard let account = try? context.fetch(descriptor).first else { return }
                    TrialManager.syncEntitlement(from: storeManager, to: account)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
