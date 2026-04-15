import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.displayName)
    private var allClients: [Client]
    @Query private var accounts: [CoachAccount]
    @Query private var imports: [ClientImport]

    private var account: CoachAccount? {
        accounts.first
    }

    private var clients: [Client] {
        allClients.filter { $0.status == .active }
    }

    @State private var selectedClient: Client?
    @State private var showingOnboarding = false
    @State private var showingAddClient = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var selectedFilter: AttentionBucket?
    @State private var clientScores: [UUID: Double] = [:]
    @State private var bulkReportResult: BulkReportResult? = nil
    @State private var isBulkGenerating = false

    private var filteredAndSortedClients: [Client] {
        var result = clients

        // Filter by attention bucket
        if let filter = selectedFilter {
            result = result.filter { client in
                if let score = clientScores[client.id] {
                    return AttentionBucket.from(score: score) == filter
                }
                return false
            }
        }

        // Sort by attention score descending (highest attention needed first)
        result.sort { a, b in
            let scoreA = clientScores[a.id] ?? 0
            let scoreB = clientScores[b.id] ?? 0
            return scoreA > scoreB
        }

        return result
    }

    var body: some View {
        NavigationSplitView {
            ClientListView(
                clients: filteredAndSortedClients,
                selectedClient: $selectedClient,
                selectedFilter: $selectedFilter,
                clientScores: clientScores,
                onAddClient: {
                    if let account, TrialManager.canAddClient(account: account, currentActiveCount: clients.count) {
                        showingAddClient = true
                    } else {
                        showingPaywall = true
                    }
                }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 280)
        } detail: {
            if let client = selectedClient {
                ClientDetailView(client: client)
            } else {
                ContentUnavailableView(
                    "Select a Client",
                    systemImage: "person.crop.circle",
                    description: Text("Choose a client from the sidebar to view their health data.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let account, TrialManager.canAddClient(account: account, currentActiveCount: clients.count) {
                        showingAddClient = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Label("Add Client", systemImage: "plus")
                }
                .accessibilityIdentifier("toolbar-add-client")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    generateAllReports()
                } label: {
                    if isBulkGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Generate All Reports", systemImage: "doc.badge.arrow.up")
                    }
                }
                .disabled(clients.isEmpty || isBulkGenerating)
                .help("Generate and export a PDF report for every active client this week")
                .accessibilityIdentifier("generate-all-reports-button")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Plans", systemImage: "creditcard")
                }
                .accessibilityIdentifier("toolbar-plans")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .accessibilityIdentifier("toolbar-settings")
            }
        }
        .alert(bulkResultTitle, isPresented: Binding(
            get: { bulkReportResult != nil },
            set: { if !$0 { bulkReportResult = nil } }
        )) {
            Button("OK") { bulkReportResult = nil }
        } message: {
            Text(bulkResultMessage)
        }
        .sheet(isPresented: $showingOnboarding, onDismiss: { refreshScores() }) {
            if let account {
                OnboardingContainerView(account: account) {
                    showingOnboarding = false
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            ClientFormView(mode: .create)
        }
        .sheet(isPresented: $showingSettings) {
            if let account {
                SettingsView(account: account)
            } else {
                Text("Loading…").onAppear { showingSettings = false }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            if let account {
                PaywallView(account: account)
            } else {
                Text("Loading…").onAppear { showingPaywall = false }
            }
        }
        .onAppear {
            refreshScores()
            if let account, !account.onboardingCompleted {
                showingOnboarding = true
            }
        }
        .onChange(of: allClients.count) {
            // Clear selection if the selected client was deleted
            if let selected = selectedClient, !allClients.contains(where: { $0.id == selected.id }) {
                selectedClient = nil
            }
            refreshScores()
        }
        .onChange(of: imports.count) {
            refreshScores()
        }
    }

    private func refreshScores() {
        var scores: [UUID: Double] = [:]
        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: Date())
        for client in clients {
            let trend = BaselineEngine.computeTrend(metrics: client.metrics)
            let completeness = CompletenessCalculator.score(
                for: currentWeekStart,
                metrics: client.metrics
            )
            let result = AttentionScoreCalculator.calculate(
                trend: trend,
                completenessScore: completeness
            )
            scores[client.id] = result.total
        }
        clientScores = scores
    }

    // MARK: - Bulk report generation

    private func generateAllReports() {
        guard let account else { return }
        guard TrialManager.canGenerateReports(account: account) else {
            showingPaywall = true
            return
        }
        guard !clients.isEmpty else { return }

        isBulkGenerating = true
        let weekStart = CompletenessCalculator.mondayOfWeek(containing: Date())
        let context = modelContext
        let activeClients = clients

        Task.detached(priority: .userInitiated) {
            let result = BulkReportService.generate(
                clients: activeClients,
                weekStart: weekStart,
                context: context
            )
            await MainActor.run {
                isBulkGenerating = false
                bulkReportResult = result
            }
        }
    }

    private var bulkResultTitle: String {
        guard let result = bulkReportResult else { return "" }
        if result.failed.isEmpty {
            return "Reports exported"
        } else if result.succeeded.isEmpty {
            return "Export failed"
        } else {
            return "Export completed with errors"
        }
    }

    private var bulkResultMessage: String {
        guard let result = bulkReportResult else { return "" }
        var lines: [String] = []
        if !result.succeeded.isEmpty {
            lines.append("\(result.succeeded.count) report(s) saved successfully.")
        }
        if !result.failed.isEmpty {
            lines.append("\(result.failed.count) failed: \(result.failed.joined(separator: ", ")).")
        }
        return lines.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            CoachAccount.self, Client.self, ClientImport.self,
            MetricDaily.self, AlertEvent.self, AttentionScore.self,
            GeneratedReport.self, MetricCompleteness.self,
        ], inMemory: true)
}
