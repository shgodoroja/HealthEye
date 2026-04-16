import Foundation
import SwiftData

// MARK: - Result types

struct MetricDailySnapshot: Sendable {
    let date: Date
    let sleepMinutes: Double?
    let hrvMs: Double?
    let restingHrBpm: Double?
    let workoutMinutes: Double?
    let steps: Double?

    @MainActor
    init(metric: MetricDaily) {
        date = metric.date
        sleepMinutes = metric.sleepMinutes
        hrvMs = metric.hrvMs
        restingHrBpm = metric.restingHrBpm
        workoutMinutes = metric.workoutMinutes
        steps = metric.steps
    }

    init(
        date: Date,
        sleepMinutes: Double? = nil,
        hrvMs: Double? = nil,
        restingHrBpm: Double? = nil,
        workoutMinutes: Double? = nil,
        steps: Double? = nil
    ) {
        self.date = date
        self.sleepMinutes = sleepMinutes
        self.hrvMs = hrvMs
        self.restingHrBpm = restingHrBpm
        self.workoutMinutes = workoutMinutes
        self.steps = steps
    }
}

struct BulkReportClientSnapshot: Sendable {
    let id: UUID
    let displayName: String
    let metrics: [MetricDailySnapshot]

    @MainActor
    init(client: Client) {
        id = client.id
        displayName = client.displayName
        metrics = client.metrics.map(MetricDailySnapshot.init(metric:))
    }

    init(id: UUID = UUID(), displayName: String, metrics: [MetricDailySnapshot]) {
        self.id = id
        self.displayName = displayName
        self.metrics = metrics
    }
}

struct BulkReportFile: Sendable {
    let clientID: UUID
    let clientName: String
    let filename: String
    let data: Data
}

struct BulkReportResult: Sendable {
    let succeeded: [String]        // client display names
    let failed: [String]           // client display names
    /// Generated PDFs ready to be saved/shared by the caller.
    let pdfFiles: [BulkReportFile]
}

// MARK: - Service

struct BulkReportService {

    /// Generates one PDF per client for the given week.
    ///
    /// The caller is responsible for saving or sharing the returned `pdfFiles`
    /// in a platform-appropriate way (folder picker on macOS, share sheet on iPadOS).
    nonisolated static func generate(
        clients: [BulkReportClientSnapshot],
        week: ReportWeekRange
    ) -> BulkReportResult {
        var succeeded: [String] = []
        var failed: [String] = []
        var pdfFiles: [BulkReportFile] = []

        for client in clients {
            let reportData = reportData(for: client, week: week)
            let pdfData = PDFReportGenerator.generate(data: reportData)
            guard !pdfData.isEmpty else {
                failed.append(client.displayName)
                continue
            }

            let filename = sanitizedFilename(
                for: client.displayName,
                clientID: client.id,
                weekStart: week.weekStart
            )
            pdfFiles.append(BulkReportFile(
                clientID: client.id,
                clientName: client.displayName,
                filename: filename,
                data: pdfData
            ))
            succeeded.append(client.displayName)
        }

        return BulkReportResult(succeeded: succeeded, failed: failed, pdfFiles: pdfFiles)
    }

    nonisolated static func reportData(
        for client: BulkReportClientSnapshot,
        week: ReportWeekRange
    ) -> ReportData {
        let trend = computeTrend(
            metrics: client.metrics,
            referenceDate: week.dayAfterWeekEnd
        )
        let completeness = completenessScore(
            from: week.weekStart,
            to: week.weekEnd,
            metrics: client.metrics
        )
        let scoreResult = AttentionScoreCalculator.calculate(
            trend: trend,
            completenessScore: completeness
        )
        let alerts = AlertRuleEngine.evaluate(trend: trend)
        let narrative = WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)

        return ReportData(
            clientName: client.displayName,
            weekStart: week.weekStart,
            weekEnd: week.weekEnd,
            trend: trend,
            scoreResult: scoreResult,
            alerts: alerts,
            narrative: narrative,
            completenessScore: completeness
        )
    }

    private nonisolated static func computeTrend(
        metrics: [MetricDailySnapshot],
        referenceDate: Date
    ) -> MetricTrend {
        let cal = calendar
        let today = cal.startOfDay(for: referenceDate)

        guard let recentStart = cal.date(byAdding: .day, value: -7, to: today),
              let baselineStart = cal.date(byAdding: .day, value: -35, to: today) else {
            let empty = MetricWindow(sleepAvg: nil, hrvAvg: nil, restingHrAvg: nil, workoutAvg: nil, stepsAvg: nil, dayCount: 0)
            return MetricTrend(recent: empty, baseline: empty, sleepDelta: nil, hrvDelta: nil, restingHrDelta: nil, workoutDelta: nil, stepsDelta: nil)
        }

        let recentMetrics = metrics.filter { metric in
            let day = cal.startOfDay(for: metric.date)
            return day >= recentStart && day < today
        }
        let baselineMetrics = metrics.filter { metric in
            let day = cal.startOfDay(for: metric.date)
            return day >= baselineStart && day < recentStart
        }

        let recentWindow = computeWindow(from: recentMetrics)
        let baselineWindow = computeWindow(from: baselineMetrics)

        return MetricTrend(
            recent: recentWindow,
            baseline: baselineWindow,
            sleepDelta: percentageDelta(recent: recentWindow.sleepAvg, baseline: baselineWindow.sleepAvg),
            hrvDelta: percentageDelta(recent: recentWindow.hrvAvg, baseline: baselineWindow.hrvAvg),
            restingHrDelta: percentageDelta(recent: recentWindow.restingHrAvg, baseline: baselineWindow.restingHrAvg),
            workoutDelta: percentageDelta(recent: recentWindow.workoutAvg, baseline: baselineWindow.workoutAvg),
            stepsDelta: percentageDelta(recent: recentWindow.stepsAvg, baseline: baselineWindow.stepsAvg)
        )
    }

    private nonisolated static func computeWindow(from metrics: [MetricDailySnapshot]) -> MetricWindow {
        MetricWindow(
            sleepAvg: average(of: metrics.compactMap(\.sleepMinutes)),
            hrvAvg: average(of: metrics.compactMap(\.hrvMs)),
            restingHrAvg: average(of: metrics.compactMap(\.restingHrBpm)),
            workoutAvg: average(of: metrics.compactMap(\.workoutMinutes)),
            stepsAvg: average(of: metrics.compactMap(\.steps)),
            dayCount: metrics.count
        )
    }

    private nonisolated static func completenessScore(
        from weekStart: Date,
        to weekEnd: Date,
        metrics: [MetricDailySnapshot]
    ) -> Double {
        let cal = calendar
        let start = cal.startOfDay(for: weekStart)
        let end = cal.startOfDay(for: weekEnd)
        let days = metrics.filter { metric in
            let day = cal.startOfDay(for: metric.date)
            return day >= start && day <= end
        }

        let sleepScore = Double(days.filter { $0.sleepMinutes != nil }.count) / 7.0
        let hrvScore = Double(days.filter { $0.hrvMs != nil }.count) / 7.0
        let restingHRScore = Double(days.filter { $0.restingHrBpm != nil }.count) / 7.0
        let workoutScore = Double(days.filter { $0.workoutMinutes != nil }.count) / 7.0
        let stepsScore = Double(days.filter { $0.steps != nil }.count) / 7.0
        let metricScores = [sleepScore, hrvScore, restingHRScore, workoutScore, stepsScore]
        return metricScores.reduce(0, +) / 5.0
    }

    private nonisolated static func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private nonisolated static func percentageDelta(recent: Double?, baseline: Double?) -> Double? {
        guard let recent, let baseline, baseline != 0 else { return nil }
        return (recent - baseline) / baseline * 100.0
    }

    private nonisolated static var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Persists a successfully exported PDF as a `GeneratedReport` record.
    static func recordExport(
        client: Client,
        weekStart: Date,
        weekEnd: Date,
        pdfPath: String,
        context: ModelContext
    ) {
        let report = GeneratedReport(
            client: client,
            weekStart: weekStart,
            weekEnd: weekEnd,
            pdfPath: pdfPath
        )
        context.insert(report)
        try? context.save()
    }

    // MARK: - Private helpers

    nonisolated static func sanitizedFilename(
        for clientName: String,
        clientID: UUID? = nil,
        weekStart: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let name = clientName
            .components(separatedBy: .whitespaces).joined()
            .components(separatedBy: .punctuationCharacters).joined()
        let suffix = clientID.map { "_\($0.uuidString)" } ?? ""
        return "\(name)\(suffix)_Week_\(formatter.string(from: weekStart)).pdf"
    }
}
