import SwiftUI
import SwiftData

struct ClientListView: View {
    let clients: [Client]
    @Binding var selectedClient: Client?
    let onAddClient: () -> Void

    var body: some View {
        Group {
            if clients.isEmpty {
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
                List(clients, selection: $selectedClient) { client in
                    ClientRowView(client: client)
                        .tag(client)
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
