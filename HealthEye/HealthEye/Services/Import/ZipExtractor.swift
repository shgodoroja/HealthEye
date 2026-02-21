import Foundation

struct ZipExtractor: Sendable {
    private static let zipMagicBytes: [UInt8] = [0x50, 0x4B, 0x03, 0x04]

    static func extractExportXML(from fileURL: URL) throws -> URL {
        let isZip = try isZipFile(fileURL)

        if isZip {
            return try extractFromZip(fileURL)
        } else {
            // Assume raw XML — validate it starts with XML-like content
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let prefix = String(data: data.prefix(100), encoding: .utf8) ?? ""
            guard prefix.contains("<?xml") || prefix.contains("<HealthData") else {
                throw ImportError.invalidFile("File is neither a zip archive nor a valid Apple Health XML export")
            }
            return fileURL
        }
    }

    private static func isZipFile(_ url: URL) throws -> Bool {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let headerData = handle.readData(ofLength: 4)
        guard headerData.count == 4 else { return false }
        return Array(headerData) == zipMagicBytes
    }

    private static func extractFromZip(_ zipURL: URL) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HealthEyeImport_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", zipURL.path, tempDir.path]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ImportError.zipExtractionFailed(errorMsg)
        }

        // Look for export.xml in extracted contents
        let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent == "export.xml" {
                return fileURL
            }
        }

        throw ImportError.invalidFile("No export.xml found in zip archive")
    }
}
