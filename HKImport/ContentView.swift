import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ImportViewModel()

    private let instructions = """
    To import your own values, get an export.xml file from a device containing health data and replace the one added to this project:

    1. Open Health app
    2. Tap your avatar in the top-right corner
    3. Tap Export All Health Data
    4. Airdrop the exported file to your Mac
    5. Replace the export.xml file in the project

    Not all HealthKit record types are fully supported.
    """

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Read count: \(viewModel.readCount)")
                Text("Write count: \(viewModel.writeCount)")
            }
            .font(.body.monospacedDigit())

            Button("Start Import") {
                viewModel.startImport()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isImporting)

            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(instructions)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
    }
}

#Preview {
    ContentView()
}
