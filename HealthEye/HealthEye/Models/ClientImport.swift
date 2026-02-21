import Foundation
import SwiftData

@Model
final class ClientImport {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var sourceType: SourceType
    var fileHash: String
    var importedAt: Date
    var dateRangeStart: Date?
    var dateRangeEnd: Date?
    var importStatus: ImportStatus
    var failureReason: String?

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        sourceType: SourceType = .appleHealthXML,
        fileHash: String,
        importedAt: Date = Date(),
        dateRangeStart: Date? = nil,
        dateRangeEnd: Date? = nil,
        importStatus: ImportStatus = .success,
        failureReason: String? = nil
    ) {
        self.id = id
        self.client = client
        self.sourceType = sourceType
        self.fileHash = fileHash
        self.importedAt = importedAt
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.importStatus = importStatus
        self.failureReason = failureReason
    }
}
