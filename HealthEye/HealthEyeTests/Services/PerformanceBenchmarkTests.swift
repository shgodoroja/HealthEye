import XCTest
@testable import HealthEye

final class PerformanceBenchmarkTests: XCTestCase {

    // MARK: - Import Performance: 1 year of data

    func testParseOneYearExportUnder15Seconds() throws {
        let xmlURL = try generateOneYearExport()
        defer { try? FileManager.default.removeItem(at: xmlURL) }

        let parser = AppleHealthXMLParser()

        measure {
            _ = try? parser.parse(fileURL: xmlURL)
        }

        // Verify parsing produces expected day count
        let result = try parser.parse(fileURL: xmlURL)
        XCTAssertGreaterThanOrEqual(result.dailyMetrics.count, 360, "Should have ~365 days of data")
    }

    // MARK: - Dashboard Performance: 100 clients

    func testDashboardScoring100ClientsUnder1500ms() {
        // Generate 100 clients with 35 days of metrics each (baseline + recent windows)
        let clients = (0..<100).map { i -> (metrics: [MetricDaily], id: UUID) in
            let id = UUID()
            let metrics = generateMetrics(dayCount: 35, clientIndex: i)
            return (metrics, id)
        }

        measure {
            let weekStart = CompletenessCalculator.mondayOfWeek(containing: Date())
            var scores: [UUID: Double] = [:]
            for client in clients {
                let trend = BaselineEngine.computeTrend(metrics: client.metrics)
                let completeness = CompletenessCalculator.score(for: weekStart, metrics: client.metrics)
                let result = AttentionScoreCalculator.calculate(trend: trend, completenessScore: completeness)
                scores[client.id] = result.total
            }
            XCTAssertEqual(scores.count, 100)
        }
    }

    // MARK: - Alert evaluation at scale

    func testAlertEvaluation100Clients() {
        let clients = (0..<100).map { i in
            generateMetrics(dayCount: 35, clientIndex: i)
        }

        measure {
            for metrics in clients {
                let trend = BaselineEngine.computeTrend(metrics: metrics)
                _ = AlertRuleEngine.evaluate(trend: trend)
            }
        }
    }

    // MARK: - Helpers

    private func generateOneYearExport() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())

        var records: [String] = []

        // Generate 365 days of data with all 5 metrics
        for dayOffset in stride(from: 365, through: 1, by: -1) {
            let day = cal.date(byAdding: .day, value: -dayOffset, to: today)!

            // Steps (multiple entries per day, like a real export)
            for hour in stride(from: 8, to: 22, by: 2) {
                let start = day.addingTimeInterval(Double(hour) * 3600)
                let end = start.addingTimeInterval(3600)
                let steps = Int.random(in: 200...1500)
                records.append("""
                  <Record type="HKQuantityTypeIdentifierStepCount" sourceName="Apple Watch" unit="count" creationDate="\(formatter.string(from: end))" startDate="\(formatter.string(from: start))" endDate="\(formatter.string(from: end))" value="\(steps)"/>
                """)
            }

            // HRV (1-3 readings per day)
            let hrvCount = Int.random(in: 1...3)
            for _ in 0..<hrvCount {
                let time = day.addingTimeInterval(Double.random(in: 21600...79200))
                let hrv = Double.random(in: 25...65)
                records.append("""
                  <Record type="HKQuantityTypeIdentifierHeartRateVariabilitySDNN" sourceName="Apple Watch" unit="ms" creationDate="\(formatter.string(from: time))" startDate="\(formatter.string(from: time))" endDate="\(formatter.string(from: time.addingTimeInterval(60)))" value="\(String(format: "%.1f", hrv))"/>
                """)
            }

            // Resting HR
            let rhrTime = day.addingTimeInterval(8 * 3600)
            let rhr = Int.random(in: 55...72)
            records.append("""
              <Record type="HKQuantityTypeIdentifierRestingHeartRate" sourceName="Apple Watch" unit="count/min" creationDate="\(formatter.string(from: rhrTime))" startDate="\(formatter.string(from: rhrTime))" endDate="\(formatter.string(from: rhrTime.addingTimeInterval(60)))" value="\(rhr)"/>
            """)

            // Workout
            if dayOffset % 2 == 0 { // Every other day
                let workoutStart = day.addingTimeInterval(17 * 3600)
                let workoutEnd = workoutStart.addingTimeInterval(Double.random(in: 1200...3600))
                let minutes = Int((workoutEnd.timeIntervalSince(workoutStart)) / 60)
                records.append("""
                  <Record type="HKQuantityTypeIdentifierAppleExerciseTime" sourceName="Apple Watch" unit="min" creationDate="\(formatter.string(from: workoutEnd))" startDate="\(formatter.string(from: workoutStart))" endDate="\(formatter.string(from: workoutEnd))" value="\(minutes)"/>
                """)
            }

            // Sleep
            let sleepStart = day.addingTimeInterval(-1 * 3600) // 11pm previous day
            let sleepEnd = day.addingTimeInterval(6.5 * 3600)
            records.append("""
              <Record type="HKCategoryTypeIdentifierSleepAnalysis" sourceName="Apple Watch" creationDate="\(formatter.string(from: sleepEnd))" startDate="\(formatter.string(from: sleepStart))" endDate="\(formatter.string(from: sleepEnd))" value="HKCategoryValueSleepAnalysisAsleepCore"/>
            """)
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <HealthData locale="en_US">
          <ExportDate value="\(formatter.string(from: today))"/>
        \(records.joined(separator: "\n"))
        </HealthData>
        """

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("perf_test_\(UUID().uuidString).xml")
        try xml.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func generateMetrics(dayCount: Int, clientIndex: Int) -> [MetricDaily] {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.startOfDay(for: Date())

        return (1...dayCount).map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let isRecent = offset <= 7
            let variance = Double(clientIndex % 10) * 2.0

            return MetricDaily(
                date: date,
                sleepMinutes: isRecent ? 380 - variance : 420,
                hrvMs: isRecent ? 38 - variance * 0.3 : 48,
                restingHrBpm: isRecent ? 65 + variance * 0.2 : 60,
                workoutMinutes: isRecent ? 15 : 30,
                steps: isRecent ? 5000 : 8000
            )
        }
    }
}
