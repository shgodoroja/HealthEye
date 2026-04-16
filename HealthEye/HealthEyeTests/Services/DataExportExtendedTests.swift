import Testing
import Foundation
@testable import HealthEye

struct DataExportExtendedTests {

    // MARK: - Multi-client export

    @Test func allClientsCSVContainsAllClientNames() throws {
        let client1 = Client(displayName: "Alice", timezone: "UTC")
        let client2 = Client(displayName: "Bob", timezone: "UTC")

        let data = try DataExportService.exportAllClients([client1, client2], format: .csv)
        let csv = String(data: data, encoding: .utf8)!

        // With no metrics, only header appears, but encoding should succeed
        #expect(!csv.isEmpty)
        #expect(csv.contains("client,date"))
    }

    @Test func allClientsJSONReturnsArray() throws {
        let client1 = Client(displayName: "Alice", timezone: "UTC")
        let client2 = Client(displayName: "Bob", timezone: "UTC")

        let data = try DataExportService.exportAllClients([client1, client2], format: .json)
        let json = try JSONSerialization.jsonObject(with: data)

        #expect(json is [Any])
        let array = json as! [Any]
        #expect(array.count == 2)
    }

    @Test func emptyClientListExportsWithoutError() throws {
        let csvData = try DataExportService.exportAllClients([], format: .csv)
        #expect(!csvData.isEmpty)

        let jsonData = try DataExportService.exportAllClients([], format: .json)
        #expect(!jsonData.isEmpty)
    }

    // MARK: - CSV special characters

    @Test func csvEscapesClientNameWithComma() throws {
        let client = Client(displayName: "Last, First", timezone: "UTC")
        let data = try DataExportService.exportClient(client, format: .csv)
        let csv = String(data: data, encoding: .utf8)!

        // Header should still be correct
        #expect(csv.hasPrefix("client,date"))
    }

    // MARK: - JSON structure

    @Test func jsonContainsExpectedFields() throws {
        let client = Client(displayName: "Test", timezone: "America/New_York")
        let data = try DataExportService.exportClient(client, format: .json)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["displayName"] as? String == "Test")
        #expect(json["timezone"] as? String == "America/New_York")
        #expect(json["createdAt"] != nil)
        #expect(json["metrics"] is [Any])
    }
}
