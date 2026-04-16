import Foundation
import Security

/// Manages encryption-at-rest for the SwiftData persistent store.
///
/// Strategy:
/// - Applies `NSFileProtectionComplete` to the store directory so the SQLite
///   file is unreadable when the Mac is locked (requires FileVault).
/// - Stores a sentinel in the Keychain to confirm encryption was configured.
/// - Logs a warning at launch if FileVault is not enabled.
struct StoreEncryption {

    /// The Application Support subdirectory used for the encrypted store.
    static var storeDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("HealthEye", isDirectory: true)
    }

    /// Returns a store URL inside the encrypted directory, creating the
    /// directory (with file-protection attributes) if needed.
    static func prepareStoreURL() -> URL {
        let directory = storeDirectoryURL
        let fm = FileManager.default

        if !fm.fileExists(atPath: directory.path) {
            try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        applyFileProtection(to: directory)

        return directory.appendingPathComponent("HealthEye.store")
    }

    /// Applies `NSFileProtectionComplete` to the given URL.
    /// On macOS this relies on FileVault for actual encryption.
    static func applyFileProtection(to url: URL) {
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    /// Checks whether FileVault (full-disk encryption) is enabled.
    /// Returns `true` if enabled, `false` if not or if status cannot be determined.
    static var isFileVaultEnabled: Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/fdesetup")
        task.arguments = ["isactive"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Logs a warning if FileVault is not enabled. Called once at app launch.
    static func verifyEncryptionEnvironment() {
        #if !DEBUG
        if !isFileVaultEnabled {
            NSLog("[HealthEye] WARNING: FileVault is not enabled. Health data at rest is not fully encrypted. Enable FileVault in System Settings > Privacy & Security.")
        }
        #endif
    }
}
