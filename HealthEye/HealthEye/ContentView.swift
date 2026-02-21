import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.displayName)
    private var allClients: [Client]
    @Query private var accounts: [CoachAccount]

    private var account: CoachAccount? {
        accounts.first
    }

    private var clients: [Client] {
        allClients.filter { $0.status == .active }
    }

    @State private var selectedClient: Client?
    @State private var showingAddClient = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var selectedFilter: AttentionBucket?
    @State private var clientScores: [UUID: Double] = [:]

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
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Plans", systemImage: "creditcard")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            ClientFormView(mode: .create)
        }
        .sheet(isPresented: $showingSettings) {
            if let account {
                SettingsView(account: account)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            if let account {
                PaywallView(account: account)
            }
        }
        .onAppear {
            refreshScores()
        }
        .onChange(of: allClients.count) {
            refreshScores()
        }
    }

    private func refreshScores() {
        var scores: [UUID: Double] = [:]
        for client in clients {
            let trend = BaselineEngine.computeTrend(metrics: client.metrics)
            let completeness = averageCompleteness(for: client)
            let result = AttentionScoreCalculator.calculate(
                trend: trend,
                completenessScore: completeness
            )
            scores[client.id] = result.total
        }
        clientScores = scores
    }

    private func averageCompleteness(for client: Client) -> Double {
        let records = client.completenessRecords
        guard !records.isEmpty else { return 0 }
        return records.map(\.completenessScore).reduce(0, +) / Double(records.count)
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
