import SwiftUI
import UniformTypeIdentifiers

struct ImportStepFileDropView: View {
    @Binding var selectedFileURL: URL?
    let onStartImport: () -> Void

    @State private var isDragging = false

    private var injectedImportFileURL: URL? {
        guard let path = ProcessInfo.processInfo.environment["UITEST_IMPORT_FILE_PATH"],
              !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Apple Health Export")
                .font(.title2)
                .fontWeight(.semibold)

            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDragging ? Color.accentColor.opacity(0.05) : Color.clear)
                    )

                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    if let url = selectedFileURL {
                        Text(url.lastPathComponent)
                            .font(.headline)
                        Text("Ready to import")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Drag & drop your export file here")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Accepts .zip or .xml files")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(height: 180)
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers)
            }

            HStack(spacing: 16) {
                Button("Browse...") {
                    openFilePanel()
                }
                .controlSize(.large)
                .accessibilityIdentifier("import-browse")

                if selectedFileURL != nil {
                    Button("Start Import") {
                        onStartImport()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("import-start")
                }
            }

            Spacer()
        }
        .padding(24)
        .onAppear {
            if selectedFileURL == nil, let injectedImportFileURL {
                selectedFileURL = injectedImportFileURL
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            Task { @MainActor in
                selectedFileURL = url
            }
        }
        return true
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "zip")!,
            UTType(filenameExtension: "xml")!,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select your Apple Health export file"

        if panel.runModal() == .OK {
            selectedFileURL = panel.url
        }
    }
}
