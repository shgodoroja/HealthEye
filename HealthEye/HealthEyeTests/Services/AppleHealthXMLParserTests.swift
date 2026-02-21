import Testing
import Foundation
@testable import HealthEye

struct AppleHealthXMLParserTests {
    private func fixtureURL(_ name: String) -> URL {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "xml", subdirectory: "TestFixtures") else {
            // Fallback to file path relative to test source
            let testDir = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("TestFixtures")
                .appendingPathComponent("\(name).xml")
            return testDir
        }
        return url
    }

    @Test func parsesStepCountAsSumPerDay() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        // Feb 10: 1500 + 3000 = 4500, Feb 11: 5000
        let feb10 = result.dailyMetrics["2026-02-10"]
        #expect(feb10?.stepsSum == 4500)

        let feb11 = result.dailyMetrics["2026-02-11"]
        #expect(feb11?.stepsSum == 5000)
    }

    @Test func parsesHRVAsMeanPerDay() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        // Feb 10: (45 + 55) / 2 = 50
        let feb10 = result.dailyMetrics["2026-02-10"]
        #expect(feb10?.hrvMean == 50.0)
    }

    @Test func parsesRestingHRAsLastReadingPerDay() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        // Feb 10: two readings at 08:00 (62) and 14:00 (60), last is 60
        let feb10 = result.dailyMetrics["2026-02-10"]
        #expect(feb10?.restingHrLast?.value == 60)
    }

    @Test func parsesWorkoutMinutesAsSumPerDay() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        let feb10 = result.dailyMetrics["2026-02-10"]
        #expect(feb10?.workoutMinutesSum == 30)

        let feb11 = result.dailyMetrics["2026-02-11"]
        #expect(feb11?.workoutMinutesSum == 45)
    }

    @Test func parsesSleepExcludingInBedAndAwake() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        // Core: 23:00 Feb 9 to 06:30 Feb 10 = 450 min (assigned to Feb 10)
        // Deep: 01:00 to 03:00 Feb 10 = 120 min (assigned to Feb 10)
        // InBed should be excluded
        let feb10 = result.dailyMetrics["2026-02-10"]
        #expect(feb10?.sleepMinutesSum == 570) // 450 + 120
    }

    @Test func sleepAssignedToEndDateDay() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        // Sleep crossing midnight (start Feb 9 23:00, end Feb 10 06:30) should be assigned to Feb 10
        let feb9 = result.dailyMetrics["2026-02-09"]
        #expect(feb9?.sleepMinutesSum == nil)
    }

    @Test func parsesExportDate() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        #expect(result.exportDate != nil)
    }

    @Test func handlesEmptyExport() throws {
        // Create a minimal empty export in memory
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <HealthData locale="en_US">
        </HealthData>
        """
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty_export.xml")
        try xml.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: tempURL)

        #expect(result.dailyMetrics.isEmpty)
        #expect(result.totalRecordsParsed == 0)
    }

    @Test func handlesMalformedData() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("malformed_export"))

        // Only the valid record (1000 steps) should produce metric data
        #expect(result.dailyMetrics["2026-02-10"]?.stepsSum == 1000)
        // All 3 records match relevant types so the counter increments for each
        #expect(result.totalRecordsParsed == 3)
    }

    @Test func dateRangesAreCorrect() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("minimal_export"))

        #expect(result.dateRangeStart != nil)
        #expect(result.dateRangeEnd != nil)
        #expect(result.dateRangeStart! <= result.dateRangeEnd!)
    }

    @Test func reportsProgressEvery10kRecords() throws {
        var progressCounts: [Int] = []
        let parser = AppleHealthXMLParser { count in
            progressCounts.append(count)
        }
        _ = try parser.parse(fileURL: fixtureURL("minimal_export"))

        // With < 10k records, no progress should be reported
        #expect(progressCounts.isEmpty)
    }

    @Test func missingMetricsExportParsesCorrectly() throws {
        let parser = AppleHealthXMLParser()
        let result = try parser.parse(fileURL: fixtureURL("missing_metrics_export"))

        // Only steps, no HRV/HR/sleep/workout
        let feb10 = result.dailyMetrics["2026-02-10"]
        #expect(feb10?.stepsSum == 2000)
        #expect(feb10?.hrvMean == nil)
        #expect(feb10?.restingHrLast == nil)
        #expect(feb10?.workoutMinutesSum == nil)
        #expect(feb10?.sleepMinutesSum == nil)
    }
}

private final class BundleToken {}
