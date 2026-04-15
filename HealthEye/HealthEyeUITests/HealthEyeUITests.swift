import XCTest

final class HealthEyeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddClientFromEmptyWorkspace() throws {
        let app = launchApp()

        let addButton = app.buttons["empty-add-client"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["client-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Jordan Coach")

        let saveButton = app.buttons["client-form-save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Jordan Coach"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testImportFlowUpdatesDashboardFilter() throws {
        let importFileURL = try makeImportFixtureFile()
        defer { try? FileManager.default.removeItem(at: importFileURL) }

        let app = launchApp(environment: [
            "UITEST_IMPORT_FILE_PATH": importFileURL.path,
        ])

        app.buttons["empty-add-client"].tap()

        let nameField = app.textFields["client-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Jordan Medium")
        app.buttons["client-form-save"].tap()

        let clientLabel = app.staticTexts["Jordan Medium"]
        XCTAssertTrue(clientLabel.waitForExistence(timeout: 5))
        clientLabel.tap()

        let importButton = app.buttons["import-health-data-button"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))
        importButton.tap()

        let continueButton = app.buttons["import-continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        let startImportButton = app.buttons["import-start"]
        XCTAssertTrue(startImportButton.waitForExistence(timeout: 5))
        startImportButton.tap()

        XCTAssertTrue(app.staticTexts["import-success-title"].waitForExistence(timeout: 10))
        app.buttons["import-done"].tap()

        let mediumFilter = app.buttons["filter-medium"]
        XCTAssertTrue(mediumFilter.waitForExistence(timeout: 5))
        mediumFilter.tap()

        XCTAssertTrue(clientLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testExpiredTrialBlocksReportGeneration() throws {
        let app = launchApp(environment: [
            "UITEST_SCENARIO": "expired_trial_with_client",
        ])

        let clientLabel = app.staticTexts["Taylor Client"]
        XCTAssertTrue(clientLabel.waitForExistence(timeout: 5))
        clientLabel.tap()

        let generateButton = app.buttons["generate-report-button"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        XCTAssertTrue(app.staticTexts["paywall-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["paywall-expired-banner"].waitForExistence(timeout: 5))
    }

    private func launchApp(environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    private func makeImportFixtureFile() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        let today = Calendar.utc.startOfDay(for: Date())
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
                    value: isRecent ? "5500" : "8000",
                    formatter: formatter
                )
            )
            records.append(
                recordLine(
                    type: "HKQuantityTypeIdentifierAppleExerciseTime",
                    start: day.addingTimeInterval(18 * 3600),
                    end: day.addingTimeInterval(18 * 3600 + 1800),
                    value: isRecent ? "12" : "30",
                    formatter: formatter
                )
            )
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <HealthData locale="en_US">
          <ExportDate value="\(exportDate)"/>
        \(records.joined(separator: "\n"))
        </HealthData>
        """

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("xml")
        try xml.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func recordLine(
        type: String,
        start: Date,
        end: Date,
        value: String,
        formatter: DateFormatter
    ) -> String {
        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)
        return """
          <Record type="\(type)" sourceName="Health" sourceVersion="1.0" unit="count" creationDate="\(startString)" startDate="\(startString)" endDate="\(endString)" value="\(value)"/>
        """
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
