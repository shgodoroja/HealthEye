import SwiftUI
import SwiftData

struct ClientRowView: View {
    let client: Client

    private var lastImportDate: Date? {
        client.imports
            .filter { $0.importStatus == .success }
            .map(\.importedAt)
            .max()
    }

    private var overallCompleteness: Double? {
        let scores = client.completenessRecords.map(\.completenessScore)
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(client.displayName)
                    .font(.headline)

                if let lastImport = lastImportDate {
                    Text("Last import: \(lastImport, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No imports yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let score = overallCompleteness {
                CompletenessIndicatorView(score: score)
            }
        }
        .padding(.vertical, 2)
    }
}
