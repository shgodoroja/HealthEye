import Testing
import Foundation
@testable import HealthEye

struct FileHasherTests {
    @Test func hashIsConsistent() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("hash_test.txt")
        try "Hello, World!".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let hash1 = try FileHasher.sha256Hash(of: tempURL)
        let hash2 = try FileHasher.sha256Hash(of: tempURL)

        #expect(hash1 == hash2)
    }

    @Test func differentFilesProduceDifferentHashes() throws {
        let url1 = FileManager.default.temporaryDirectory.appendingPathComponent("hash_a.txt")
        let url2 = FileManager.default.temporaryDirectory.appendingPathComponent("hash_b.txt")
        try "File A".write(to: url1, atomically: true, encoding: .utf8)
        try "File B".write(to: url2, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: url1)
            try? FileManager.default.removeItem(at: url2)
        }

        let hash1 = try FileHasher.sha256Hash(of: url1)
        let hash2 = try FileHasher.sha256Hash(of: url2)

        #expect(hash1 != hash2)
    }

    @Test func emptyFileProducesKnownHash() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("hash_empty.txt")
        try Data().write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let hash = try FileHasher.sha256Hash(of: tempURL)

        // SHA-256 of empty data
        #expect(hash == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }
}
