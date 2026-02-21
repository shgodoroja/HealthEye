import SwiftUI
import SwiftData

struct ImportWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let client: Client
    @State private var currentStep: ImportWizardStep = .instructions
    @State private var selectedFileURL: URL?
    @State private var importService: AppleHealthImportService?

    enum ImportWizardStep {
        case instructions
        case fileSelection
        case progress
        case result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 16) {
                stepIndicator("1. Instructions", isActive: currentStep == .instructions)
                stepIndicator("2. Select File", isActive: currentStep == .fileSelection)
                stepIndicator("3. Importing", isActive: currentStep == .progress)
                stepIndicator("4. Results", isActive: currentStep == .result)
            }
            .padding()
            .background(.bar)

            Divider()

            // Content
            Group {
                switch currentStep {
                case .instructions:
                    ImportStepInstructionsView {
                        currentStep = .fileSelection
                    }
                case .fileSelection:
                    ImportStepFileDropView(selectedFileURL: $selectedFileURL) {
                        startImport()
                    }
                case .progress:
                    if let service = importService {
                        ImportStepProgressView(importService: service)
                    }
                case .result:
                    if let service = importService {
                        ImportStepResultView(importService: service) {
                            dismiss()
                        } onRetry: {
                            currentStep = .fileSelection
                            selectedFileURL = nil
                            importService?.reset()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 550, minHeight: 450)
    }

    private func stepIndicator(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(isActive ? .bold : .regular)
            .foregroundStyle(isActive ? .primary : .secondary)
    }

    private func startImport() {
        guard let fileURL = selectedFileURL else { return }
        guard currentStep != .progress else { return }

        let container = modelContext.container
        let service = AppleHealthImportService(modelContainer: container)
        importService = service
        currentStep = .progress

        Task {
            await service.importFile(fileURL, for: client)
            // Import finished — move to result step
            currentStep = .result
        }
    }
}
