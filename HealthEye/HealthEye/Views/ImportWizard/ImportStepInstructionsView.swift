import SwiftUI

struct ImportStepInstructionsView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to Export Apple Health Data")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                instructionStep(number: 1, text: "Open the **Health** app on your iPhone.")
                instructionStep(number: 2, text: "Tap your **profile picture** in the top-right corner.")
                instructionStep(number: 3, text: "Scroll down and tap **Export All Health Data**.")
                instructionStep(number: 4, text: "Confirm the export and wait for it to complete.")
                instructionStep(number: 5, text: "Share the exported zip file to your Mac via **AirDrop**, **Files**, or **email**.")
            }

            Spacer()

            HStack {
                Spacer()
                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
    }

    private func instructionStep(number: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            Text(text)
                .font(.body)
        }
    }
}
