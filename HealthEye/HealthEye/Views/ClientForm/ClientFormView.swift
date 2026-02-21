import SwiftUI
import SwiftData

enum ClientFormMode {
    case create
    case edit(Client)
}

struct ClientFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [CoachAccount]

    let mode: ClientFormMode

    @State private var displayName: String = ""
    @State private var timezone: String = TimeZone.current.identifier
    @State private var notes: String = ""
    @State private var showArchiveConfirmation = false
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingClient: Client? {
        if case .edit(let client) = mode { return client }
        return nil
    }

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Client Information") {
                    TextField("Name", text: $displayName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Timezone", selection: $timezone) {
                        ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { tz in
                            Text(tz).tag(tz)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if isEditing {
                    Section {
                        Button("Archive Client", role: .destructive) {
                            showArchiveConfirmation = true
                        }

                        Button("Delete Permanently", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save Changes" : "Add Client") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 350)
        .navigationTitle(isEditing ? "Edit Client" : "New Client")
        .onAppear {
            if let client = editingClient {
                displayName = client.displayName
                timezone = client.timezone
                notes = client.notes ?? ""
            }
        }
        .alert("Archive Client?", isPresented: $showArchiveConfirmation) {
            Button("Archive", role: .destructive) {
                archiveClient()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This client will be hidden from the dashboard. Their data will be preserved.")
        }
        .alert("Delete Client Permanently?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteClient()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this client and all associated data. This cannot be undone.")
        }
    }

    private func save() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let client = editingClient {
            client.displayName = trimmedName
            client.timezone = timezone
            client.notes = notes.isEmpty ? nil : notes
        } else {
            let client = Client(
                coach: accounts.first,
                displayName: trimmedName,
                timezone: timezone,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(client)
        }

        dismiss()
    }

    private func archiveClient() {
        if let client = editingClient {
            client.status = .archived
        }
        dismiss()
    }

    private func deleteClient() {
        if let client = editingClient {
            AnalyticsService.track("data_deleted", properties: ["scope": "client"])
            modelContext.delete(client)
        }
        dismiss()
    }
}
