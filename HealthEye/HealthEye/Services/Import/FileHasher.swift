import Foundation
import CryptoKit

struct FileHasher: Sendable {
    private static let bufferSize = 1_048_576 // 1 MB

    static func sha256Hash(of fileURL: URL) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
