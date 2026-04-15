import Testing
import Foundation
import SwiftData
@testable import HealthEye

struct AppleHealthImportServiceTests {
    @MainActor
    @Test func importFileCreatesDerivedRecordsWithoutOpeningClientDetail() async throws {
        let container = try makeContainer()
        let setupContext = ModelContext(container)
        let client = Client(displayName: "Imported Client", timezone: "UTC")
        setupContext.insert(client)
        try setupContext.save()

        let fileURL = try makeExportFile(referenceDate: Date())
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let service = AppleHealthImportService(modelContainer: container)
        await service.importFile(fileURL, for: client)

        guard case .completed(let summary) = service.state else {
            Issue.record("Expected import to complete successfully, got \(service.state)")
            return
        }

        #expect(summary.totalDays > 0)
        #expect(summary.metricsBreakdown.daysWithWorkout > 0)
        #expect(summary.metricsBreakdown.daysWithSteps > 0)

        let verificationContext = ModelContext(container)
        let clientID = client.id
        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: Date())

        let importDescriptor = FetchDescriptor<ClientImport>(
            predicate: #Predicate<ClientImport> { record in
                record.client?.id == clientID
            }
        )
        let scoreDescriptor = FetchDescriptor<AttentionScore>(
            predicate: #Predicate<AttentionScore> { score in
                score.client?.id == clientID && score.weekStart == currentWeekStart
            }
        )
        let alertDescriptor = FetchDescriptor<AlertEvent>(
            predicate: #Predicate<AlertEvent> { alert in
                alert.client?.id == clientID && alert.weekStart == currentWeekStart
            }
        )
        let completenessDescriptor = FetchDescriptor<MetricCompleteness>(
            predicate: #Predicate<MetricCompleteness> { record in
                record.client?.id == clientID
            }
        )

        #expect(try verificationContext.fetch(importDescriptor).count == 1)
        #expect(try verificationContext.fetch(scoreDescriptor).count == 1)
        #expect(!(try verificationContext.fetch(completenessDescriptor)).isEmpty)
        #expect(!(try verificationContext.fetch(alertDescriptor)).isEmpty)
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            CoachAccount.self,
            Client.self,
            ClientImport.self,
            MetricDaily.self,
            AlertEvent.self,
            AttentionScore.self,
            GeneratedReport.self,
            MetricCompleteness.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeExportFile(referenceDate: Date) throws -> URL {
        let xml = makeExportXML(referenceDate: referenceDate)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("xml")
        try xml.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func makeExportXML(referenceDate: Date) -> String {
        let today = Calendar.utc.startOfDay(for: referenceDate)
        let exportDate = formatter.string(from: today)

        var records: [String] = []
        for offset in stride(from: 35, through: 1, by: -1) {
            let day = Calendar.utc.date(byAdding: .day, value: -offset, to: today)!
            let isRecent = offset <= 7
            records.append(
                recordLine(
                    type: "HKQuantityTypeIdentifierStepCount",
                    start: day.addingTimeInterval(12 * 3600),
                    end: day.addingTimeInterval(12 * 3600 + 300),
                    value: isRecent ? "5500" : "8000"
                )
            )
            records.append(
                recordLine(
                    type: "HKQuantityTypeIdentifierAppleExerciseTime",
                    start: day.addingTimeInterval(18 * 3600),
                    end: day.addingTimeInterval(18 * 3600 + 1800),
                    value: isRecent ? "12" : "30"
                )
            )
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <HealthData locale="en_US">
          <ExportDate value="\(exportDate)"/>
        \(records.joined(separator: "\n"))
        </HealthData>
        """
    }

    private func recordLine(type: String, start: Date, end: Date, value: String) -> String {
        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)
        return """
          <Record type="\(type)" sourceName="Health" sourceVersion="1.0" unit="count" creationDate="\(startString)" startDate="\(startString)" endDate="\(endString)" value="\(value)"/>
        """
    }

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}

private extension Calendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
