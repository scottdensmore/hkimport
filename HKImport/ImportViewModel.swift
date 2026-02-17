import Foundation

final class ImportViewModel: ObservableObject {
    @Published var readCount: Int = 0
    @Published var writeCount: Int = 0
    @Published var isImporting: Bool = false
    @Published var statusMessage: String = "Ready to import."

    private var importer: Importer?

    func startImport() {
        readCount = 0
        writeCount = 0
        statusMessage = "Requesting Health access..."
        isImporting = true

        let importer = Importer(completion: { [weak self] in
            self?.performImport()
        }, failure: { [weak self] message in
            DispatchQueue.main.async {
                self?.statusMessage = "Import failed: \(message)"
                self?.isImporting = false
            }
        })

        importer.onReadCountUpdated = { [weak self] count in
            self?.readCount = count
        }
        importer.onWriteCountUpdated = { [weak self] count in
            self?.writeCount = count
        }

        self.importer = importer
    }

    private func performImport() {
        guard let importer else {
            DispatchQueue.main.async {
                self.statusMessage = "Import failed: importer was released unexpectedly."
                self.isImporting = false
            }
            return
        }

        guard let importFileURL = resolveImportFileURL() else {
            DispatchQueue.main.async {
                self.statusMessage = "Import failed: export.xml was not found."
                self.isImporting = false
            }
            return
        }

        guard let parser = XMLParser(contentsOf: importFileURL) else {
            DispatchQueue.main.async {
                self.statusMessage = "Import failed: unable to parse \(importFileURL.lastPathComponent)."
                self.isImporting = false
            }
            return
        }

        DispatchQueue.main.async {
            self.statusMessage = "Importing \(importFileURL.lastPathComponent)..."
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let didParse = parser.parse()
            importer.saveAllSamples()

            DispatchQueue.main.async {
                if didParse {
                    self?.statusMessage = "Import started. Writes continue in the background."
                } else {
                    let parserError = parser.parserError?.localizedDescription ?? "Unknown XML parser error."
                    self?.statusMessage = "Import failed: \(parserError)"
                }
                self?.isImporting = false
            }
        }
    }

    private func resolveImportFileURL() -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if let fileURLs = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil),
           let url = fileURLs.first(where: { $0.lastPathComponent == "export.xml" }) {
            return url
        }

        return Bundle.main.url(forResource: "export", withExtension: "xml")
    }
}
