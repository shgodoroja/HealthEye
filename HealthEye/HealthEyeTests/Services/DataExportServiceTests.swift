import Testing
import Foundation
@testable import HealthEye

struct DataExportServiceTests {

    private func makeClient(name: String = "Test Client", metricCount: Int = 3) -> Client {
        let client = Client(displayName: name, timezone: "UTC")
        // Note: metrics relationship requires SwiftData context; we test via static helpers
        return client
    }

    private func makeMetrics() -> [MetricDaily] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        return [
            MetricDaily(date: formatter.date(from: "2025-01-06")!, sleepMinutes: 420, hrvMs: 45, restingHrBpm: 62, workoutMinutes: 30, steps: 8000),
            MetricDaily(date: formatter.date(from: "2025-01-07")!, sleepMinutes: 390, hrvMs: 42, restingHrBpm: 65, workoutMinutes: 0, steps: 6000),
            MetricDaily(date: formatter.date(from: "2025-01-08")!, sleepMinutes: nil, hrvMs: 50, restingHrBpm: nil, workoutMinutes: 45, steps: 10000),
        ]
    }

    // MARK: - CSV Tests

    @Test func csvHasCorrectHeaders() throws {
        let client = makeClient()
        let data = try DataExportService.exportClient(client, format: .csv)
        let csv = String(data: data, encoding: .utf8)!
        let firstLine = csv.components(separatedBy: "\n").first!

        #expect(firstLine == "client,date,sleepMinutes,hrvMs,restingHrBpm,workoutMinutes,steps")
    }

    @Test func csvRowCountMatchesMetrics() throws {
        // Client with no metrics (empty relationship without SwiftData context)
        let client = makeClient()
        let data = try DataExportService.exportClient(client, format: .csv)
        let csv = String(data: data, encoding: .utf8)!
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Header only, no metric rows (metrics require SwiftData context)
        #expect(lines.count == 1)
    }

    // MARK: - JSON Tests

    @Test func jsonParsesBack() throws {
        let client = makeClient()
        let data = try DataExportService.exportClient(client, format: .json)

        // Should be valid JSON
        let json = try JSONSerialization.jsonObject(with: data)
        #expect(json is [String: Any])

        let dict = json as! [String: Any]
        #expect(dict["displayName"] as? String == "Test Client")
        #expect(dict["timezone"] as? String == "UTC")
    }

    @Test func emptyClientExportsWithoutError() throws {
        let client = makeClient(name: "Empty", metricCount: 0)

        let csvData = try DataExportService.exportClient(client, format: .csv)
        #expect(!csvData.isEmpty)

        let jsonData = try DataExportService.exportClient(client, format: .json)
        #expect(!jsonData.isEmpty)
    }
}
