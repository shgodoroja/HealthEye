import SwiftUI
import SwiftData

struct ClientListView: View {
    let clients: [Client]
    @Binding var selectedClient: Client?
    @Binding var selectedFilter: AttentionBucket?
    let clientScores: [UUID: Double]
    let onAddClient: () -> Void

    var body: some View {
        Group {
            if clients.isEmpty && selectedFilter == nil {
                ContentUnavailableView {
                    Label("No Clients", systemImage: "person.3")
                } description: {
                    Text("Add your first client to get started.")
                } actions: {
                    Button("Add Client") {
                        onAddClient()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 0) {
                    AttentionFilterView(selectedFilter: $selectedFilter)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)

                    if clients.isEmpty {
                        ContentUnavailableView(
                            "No Clients",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("No clients match the selected filter.")
                        )
                    } else {
                        List(clients, selection: $selectedClient) { client in
                            ClientRowView(
                                client: client,
                                attentionScore: clientScores[client.id]
                            )
                            .tag(client)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: onAddClient) {
                    Label("Add Client", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Clients")
    }
}
