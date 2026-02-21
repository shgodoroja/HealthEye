import SwiftUI

struct ImportStepProgressView: View {
    let importService: AppleHealthImportService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            Text(statusText)
                .font(.headline)

            if case .parsing(let progress) = importService.state {
                Text("\(progress.formatted()) records processed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
    }

    private var statusText: String {
        switch importService.state {
        case .idle: return "Preparing..."
        case .validating: return "Validating file..."
        case .checkingDuplicate: return "Checking for duplicates..."
        case .parsing: return "Parsing health data..."
        case .saving: return "Saving records..."
        case .completed: return "Import complete!"
        case .failed: return "Import failed"
        }
    }
}
