import XCTest
@testable import HealthEye

final class PDFReportGeneratorTests: XCTestCase {

    private func makeReportData(
        alerts: [AlertResult] = [],
        sleepAvg: Double? = 420,
        hrvAvg: Double? = 45,
        restingHrAvg: Double? = 62,
        workoutAvg: Double? = 35,
        stepsAvg: Double? = 8000
    ) -> ReportData {
        let recent = MetricWindow(
            sleepAvg: sleepAvg,
            hrvAvg: hrvAvg,
            restingHrAvg: restingHrAvg,
            workoutAvg: workoutAvg,
            stepsAvg: stepsAvg,
            dayCount: 7
        )
        let baseline = MetricWindow(
            sleepAvg: 450,
            hrvAvg: 50,
            restingHrAvg: 60,
            workoutAvg: 40,
            stepsAvg: 10000,
            dayCount: 28
        )
        let trend = MetricTrend(
            recent: recent,
            baseline: baseline,
            sleepDelta: sleepAvg != nil ? ((sleepAvg! - 450) / 450 * 100) : nil,
            hrvDelta: hrvAvg != nil ? ((hrvAvg! - 50) / 50 * 100) : nil,
            restingHrDelta: restingHrAvg != nil ? ((restingHrAvg! - 60) / 60 * 100) : nil,
            workoutDelta: workoutAvg != nil ? ((workoutAvg! - 40) / 40 * 100) : nil,
            stepsDelta: stepsAvg != nil ? ((stepsAvg! - 10000) / 10000 * 100) : nil
        )

        let scoreResult = AttentionScoreCalculator.calculate(
            trend: trend,
            completenessScore: 0.8
        )
        let narrative = WeeklyNarrativeGenerator.generate(trend: trend, alerts: alerts)

        return ReportData(
            clientName: "John Doe",
            weekStart: Date(timeIntervalSince1970: 1707091200), // 2024-02-05
            weekEnd: Date(timeIntervalSince1970: 1707609600),   // 2024-02-11
            trend: trend,
            scoreResult: scoreResult,
            alerts: alerts,
            narrative: narrative,
            completenessScore: 0.8
        )
    }

    func testGenerateProducesNonEmptyData() {
        let data = makeReportData()
        let pdf = PDFReportGenerator.generate(data: data)
        XCTAssertFalse(pdf.isEmpty, "PDF data should not be empty")
    }

    func testPDFStartsWithMagicBytes() {
        let data = makeReportData()
        let pdf = PDFReportGenerator.generate(data: data)
        // PDF files start with %PDF
        let header = String(data: pdf.prefix(4), encoding: .ascii)
        XCTAssertEqual(header, "%PDF", "PDF should start with %PDF magic bytes")
    }

    func testGenerateWithAllSectionsPopulated() {
        let alerts = [
            AlertResult(ruleCode: "AR-001", severity: .high, explanation: "Recovery risk detected"),
            AlertResult(ruleCode: "AR-002", severity: .medium, explanation: "Sleep dropped 20%"),
        ]
        let data = makeReportData(alerts: alerts)
        let pdf = PDFReportGenerator.generate(data: data)
        XCTAssertGreaterThan(pdf.count, 100, "PDF with all sections should have substantial content")
    }

    func testGenerateWithNoAlerts() {
        let data = makeReportData(alerts: [])
        let pdf = PDFReportGenerator.generate(data: data)
        XCTAssertFalse(pdf.isEmpty, "PDF should generate even with no alerts")
        let header = String(data: pdf.prefix(4), encoding: .ascii)
        XCTAssertEqual(header, "%PDF")
    }

    func testGenerateWithMissingMetricData() {
        let data = makeReportData(
            sleepAvg: nil,
            hrvAvg: nil,
            restingHrAvg: nil,
            workoutAvg: nil,
            stepsAvg: nil
        )
        let pdf = PDFReportGenerator.generate(data: data)
        XCTAssertFalse(pdf.isEmpty, "PDF should generate even with missing metric data")
        let header = String(data: pdf.prefix(4), encoding: .ascii)
        XCTAssertEqual(header, "%PDF")
    }

    func testSaveToFile() throws {
        let data = makeReportData()
        let pdf = PDFReportGenerator.generate(data: data)

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_report_\(UUID().uuidString).pdf")

        try PDFReportGenerator.save(data: pdf, to: fileURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let savedData = try Data(contentsOf: fileURL)
        XCTAssertEqual(savedData.count, pdf.count)

        // Cleanup
        try FileManager.default.removeItem(at: fileURL)
    }
}
