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

    var body: some View {
        NavigationSplitView {
            ClientListView(
                clients: clients,
                selectedClient: $selectedClient,
                onAddClient: { showingAddClient = true }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
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
