import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Generic export document for .fileExporter

private struct DataFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .json, .data] }

    let data: Data
    let contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        contentType = .data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Main view

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: CoachAccount

    @Query(sort: \Client.displayName)
    private var allClients: [Client]

    private var activeClients: [Client] {
        allClients.filter { $0.status == .active }
    }

    @State private var selectedExportClient: Client?
    @State private var selectedDeleteClient: Client?
    @State private var showDeleteClientConfirmation = false
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteAllFinalConfirmation = false
    @State private var exportError: String?

    // Pending export state — set by export actions, consumed by .fileExporter.
    @State private var pendingExportData: Data?
    @State private var pendingExportName = ""
    @State private var pendingExportType: UTType = .data
    @State private var showingExporter = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding()
            .background(.background)

            Divider()

            Form {
                accountSection
                dataExportSection
                dataManagementSection
                aboutSection
            }
            .formStyle(.grouped)
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 500)
#endif
        .fileExporter(
            isPresented: $showingExporter,
            document: pendingExportData.map { DataFile(data: $0, contentType: pendingExportType) },
            contentType: pendingExportType,
            defaultFilename: pendingExportName
        ) { result in
            if case .failure(let error) = result {
                exportError = "Failed to save: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            LabeledContent("Email") {
                Text(account.email.isEmpty ? "Not set" : account.email)
                    .foregroundStyle(account.email.isEmpty ? .secondary : .primary)
            }

            LabeledContent("Plan") {
                Text(account.planType.rawValue.capitalized)
            }

            if account.planType == .trial {
                let daysLeft = TrialManager.trialDaysRemaining(account: account)
                LabeledContent("Trial") {
                    if TrialManager.isTrialExpired(account: account) {
                        Text("Expired").foregroundStyle(.red)
                    } else {
                        Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s") remaining")
                            .foregroundStyle(.orange)
                    }
                }
            }

            LabeledContent("Active Clients") {
                Text("\(activeClients.count) / \(TrialManager.clientLimit(for: account.planType))")
            }
        }
    }

    // MARK: - Data Export

    private var dataExportSection: some View {
        Section("Data Export") {
            if !activeClients.isEmpty {
                Picker("Client", selection: $selectedExportClient) {
                    Text("Select a client").tag(nil as Client?)
                    ForEach(activeClients, id: \.id) { client in
                        Text(client.displayName).tag(client as Client?)
                    }
                }

                HStack {
                    Button("Export CSV") { exportSingleClient(format: .csv, ext: "csv") }
                        .disabled(selectedExportClient == nil)

                    Button("Export JSON") { exportSingleClient(format: .json, ext: "json") }
                        .disabled(selectedExportClient == nil)
                }
            }

            HStack {
                Button("Export All Clients (CSV)") { exportAllClients(format: .csv, ext: "csv") }
                    .disabled(activeClients.isEmpty)

                Button("Export All Clients (JSON)") { exportAllClients(format: .json, ext: "json") }
                    .disabled(activeClients.isEmpty)
            }

            if let error = exportError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        Section("Data Management") {
            if !activeClients.isEmpty {
                Picker("Client to delete", selection: $selectedDeleteClient) {
                    Text("Select a client").tag(nil as Client?)
                    ForEach(activeClients, id: \.id) { client in
                        Text(client.displayName).tag(client as Client?)
                    }
                }

                Button("Delete Client Permanently", role: .destructive) {
                    showDeleteClientConfirmation = true
                }
                .disabled(selectedDeleteClient == nil)
            }

            Button("Delete All Data", role: .destructive) {
                showDeleteAllConfirmation = true
            }
        }
        .alert("Delete Client?", isPresented: $showDeleteClientConfirmation) {
            Button("Delete", role: .destructive) { deleteSelectedClient() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(selectedDeleteClient?.displayName ?? "")\" and all associated data. This cannot be undone.")
        }
        .alert("Delete All Data?", isPresented: $showDeleteAllConfirmation) {
            Button("Continue", role: .destructive) { showDeleteAllFinalConfirmation = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete ALL client data. Are you sure you want to proceed?")
        }
        .alert("Final Confirmation", isPresented: $showDeleteAllFinalConfirmation) {
            Button("Delete Everything", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is irreversible. All clients, metrics, reports, and history will be permanently deleted.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            Text("HealthEye is designed for coaching insights only. It does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional for medical decisions.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledContent("Version") { Text("1.0.0") }
        }
    }

    // MARK: - Actions

    private func exportSingleClient(format: ExportFormat, ext: String) {
        guard let client = selectedExportClient else { return }
        exportError = nil
        do {
            let data = try DataExportService.exportClient(client, format: format)
            let name = client.displayName.replacingOccurrences(of: " ", with: "")
            scheduleExport(data: data, fileName: "\(name)_export.\(ext)", ext: ext)
            AnalyticsService.track("data_exported", properties: ["format": ext, "scope": "single"])
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportAllClients(format: ExportFormat, ext: String) {
        exportError = nil
        do {
            let data = try DataExportService.exportAllClients(activeClients, format: format)
            scheduleExport(data: data, fileName: "healtheye_export.\(ext)", ext: ext)
            AnalyticsService.track("data_exported", properties: ["format": ext, "scope": "all"])
        } catch {
            exportError = error.localizedDescription
        }
    }

    /// Stores the export payload and triggers the system file exporter sheet.
    private func scheduleExport(data: Data, fileName: String, ext: String) {
        pendingExportData = data
        pendingExportName = fileName
        pendingExportType = ext == "csv" ? .commaSeparatedText : .json
        showingExporter = true
    }

    private func deleteSelectedClient() {
        guard let client = selectedDeleteClient else { return }
        AnalyticsService.track("data_deleted", properties: ["scope": "client"])
        modelContext.delete(client)
        selectedDeleteClient = nil
    }

    private func deleteAllData() {
        AnalyticsService.track("data_deleted", properties: ["scope": "all"])
        for client in allClients { modelContext.delete(client) }
    }
}
