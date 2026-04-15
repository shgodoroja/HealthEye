import Testing
import Foundation
import SwiftData
@testable import HealthEye

struct ClientInsightsRefreshServiceTests {
    @MainActor
    @Test func refreshPersistsDerivedRecordsAndClearsStaleAlerts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let referenceDate = makeDate("2026-04-15")
        let currentWeekStart = CompletenessCalculator.mondayOfWeek(containing: referenceDate)

        let client = Client(displayName: "Coach Client", timezone: "UTC")
        context.insert(client)

        for offset in stride(from: 35, through: 1, by: -1) {
            let date = Calendar.utc.date(byAdding: .day, value: -offset, to: referenceDate)!
            let isRecent = offset <= 7
            let metric = MetricDaily(
                client: client,
                date: date,
                workoutMinutes: isRecent ? 12 : 30,
                steps: isRecent ? 5500 : 8000
            )
            context.insert(metric)
        }
        try context.save()

        let firstSnapshot = try ClientInsightsRefreshService.refresh(
            client: client,
            context: context,
            referenceDate: referenceDate
        )

        #expect(!firstSnapshot.weeklyCompleteness.isEmpty)
        #expect(firstSnapshot.alerts.contains(where: { $0.ruleCode == "AR-003" }))
        #expect(firstSnapshot.alerts.contains(where: { $0.ruleCode == "AR-004" }))

        let clientID = client.id
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

        #expect(try context.fetch(scoreDescriptor).count == 1)
        #expect(try context.fetch(alertDescriptor).count == 2)
        #expect(!(try context.fetch(completenessDescriptor)).isEmpty)

        let recentStart = Calendar.utc.date(byAdding: .day, value: -7, to: referenceDate)!
        for metric in client.metrics where metric.date >= recentStart {
            metric.workoutMinutes = 30
            metric.steps = 8000
        }
        try context.save()

        let secondSnapshot = try ClientInsightsRefreshService.refresh(
            client: client,
            context: context,
            referenceDate: referenceDate
        )

        #expect(secondSnapshot.alerts.isEmpty)
        #expect(try context.fetch(alertDescriptor).isEmpty)
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

    private func makeDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)!
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
