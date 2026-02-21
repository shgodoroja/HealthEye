import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.displayName)
    private var allClients: [Client]

    private var clients: [Client] {
        allClients.filter { $0.status == .active }
    }

    @State private var selectedClient: Client?
    @State private var showingAddClient = false
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
                onAddClient: { showingAddClient = true }
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
        .sheet(isPresented: $showingAddClient) {
            ClientFormView(mode: .create)
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
