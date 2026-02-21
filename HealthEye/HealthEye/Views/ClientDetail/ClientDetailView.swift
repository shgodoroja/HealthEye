import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let client: Client

    @State private var showingImportWizard = false
    @State private var showingEditForm = false
    @State private var weeklyCompleteness: [WeeklyCompleteness] = []

    private var sortedImports: [ClientImport] {
        client.imports.sorted { $0.importedAt > $1.importedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(client.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(client.timezone)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let notes = client.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()

                    Button("Edit") {
                        showingEditForm = true
                    }

                    Button("Import Health Data") {
                        showingImportWizard = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                Divider()

                // Import History
                importHistorySection

                // Weekly Completeness
                if !weeklyCompleteness.isEmpty {
                    completenessSection
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingImportWizard, onDismiss: refreshCompleteness) {
            ImportWizardView(client: client)
        }
        .sheet(isPresented: $showingEditForm) {
            ClientFormView(mode: .edit(client))
        }
        .onAppear {
            refreshCompleteness()
        }
    }

    private var importHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import History")
                .font(.headline)

            if sortedImports.isEmpty {
                Text("No imports yet. Import health data to see metrics.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(sortedImports, id: \.id) { importRecord in
                    HStack {
                        Image(systemName: importRecord.importStatus == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(importRecord.importStatus == .success ? .green : .red)

                        Text(importRecord.importedAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())

                        Spacer()

                        if let start = importRecord.dateRangeStart, let end = importRecord.dateRangeEnd {
                            Text("\(start.formatted(.dateTime.month(.abbreviated).day())) — \(end.formatted(.dateTime.month(.abbreviated).day().year()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(importRecord.importStatus.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                importRecord.importStatus == .success
                                    ? Color.green.opacity(0.1)
                                    : Color.red.opacity(0.1),
                                in: Capsule()
                            )
                    }
                    .padding(.vertical, 4)

                    if let reason = importRecord.failureReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private var completenessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Data Completeness")
                .font(.headline)

            // Table header
            HStack {
                Text("Week")
                    .frame(width: 100, alignment: .leading)
                Text("Sleep")
                    .frame(width: 50)
                Text("HRV")
                    .frame(width: 50)
                Text("RHR")
                    .frame(width: 50)
                Text("Workout")
                    .frame(width: 60)
                Text("Steps")
                    .frame(width: 50)
                Text("Score")
                    .frame(width: 60)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(weeklyCompleteness.reversed(), id: \.weekStart) { week in
                MetricCompletenessRowView(week: week)
            }
        }
    }

    private func refreshCompleteness() {
        let metrics = client.metrics
        weeklyCompleteness = CompletenessCalculator.calculateWeeklyCompleteness(metrics: metrics)

        // Save completeness records
        do {
            try CompletenessCalculator.saveCompleteness(
                weeklyData: weeklyCompleteness,
                client: client,
                context: modelContext
            )
        } catch {
            // Non-fatal — UI still works from computed data
        }
    }
}
