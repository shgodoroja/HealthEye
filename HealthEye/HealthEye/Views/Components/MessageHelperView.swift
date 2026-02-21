import SwiftUI

struct MessageHelperView: View {
    let messages: [String]
    @State private var copiedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Messages")
                .font(.headline)

            if messages.isEmpty {
                Text("No suggested messages available.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                    HStack(alignment: .top) {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message, forType: .string)
                            copiedIndex = index
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if copiedIndex == index {
                                    copiedIndex = nil
                                }
                            }
                        } label: {
                            if copiedIndex == index {
                                Label("Copied", systemImage: "checkmark")
                                    .font(.caption)
                            } else {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}
