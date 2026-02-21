import Foundation
import SwiftData

@Model
final class GeneratedReport {
    @Attribute(.unique) var id: UUID
    var client: Client?
    var weekStart: Date
    var weekEnd: Date
    var pdfPath: String
    var generatedAt: Date
    var version: String

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        weekStart: Date,
        weekEnd: Date,
        pdfPath: String,
        generatedAt: Date = Date(),
        version: String = "1.0"
    ) {
        self.id = id
        self.client = client
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.pdfPath = pdfPath
        self.generatedAt = generatedAt
        self.version = version
    }
}
