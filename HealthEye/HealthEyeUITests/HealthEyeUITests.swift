import XCTest

final class HealthEyeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddClientFromEmptyWorkspace() throws {
        let app = launchApp()

        let addButton = app.buttons["empty-add-client"]
        if !addButton.waitForExistence(timeout: 5) {
            print("DEBUG HIERARCHY: \(app.debugDescription)")
        }
        XCTAssertTrue(addButton.exists)
        addButton.tap()

        let nameField = app.textFields["client-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Jordan Coach")

        let saveButton = app.buttons["client-form-save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        // The client name may appear in both the sidebar row and the auto-selected detail
        // header — use firstMatch to avoid an ambiguous-element failure.
        XCTAssertTrue(app.staticTexts["Jordan Coach"].firstMatch.waitForExistence(timeout: 5))
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

        // Tap the sidebar row — on macOS this is an outline cell; on iPad a table cell.
        // Either way the detail header lives in a ScrollView, so querying from the
        // sidebar-specific container avoids any ambiguous-element errors.
        let sidebarLabel = sidebarRow(labeled: "Jordan Medium", in: app)
        XCTAssertTrue(sidebarLabel.waitForExistence(timeout: 5))
        sidebarLabel.tap()

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

        XCTAssertTrue(sidebarLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testExpiredTrialBlocksReportGeneration() throws {
        let app = launchApp(environment: [
            "UITEST_SCENARIO": "expired_trial_with_client",
        ])

        let sidebarLabel = sidebarRow(labeled: "Taylor Client", in: app)
        XCTAssertTrue(sidebarLabel.waitForExistence(timeout: 5))
        sidebarLabel.tap()

        let generateButton = app.buttons["generate-report-button"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 10))
        generateButton.tap()

        XCTAssertTrue(app.staticTexts["paywall-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["paywall-expired-banner"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActiveTrialCanOpenReportPreview() throws {
        let app = launchApp(environment: [
            "UITEST_SCENARIO": "active_trial_with_client",
        ])

        let sidebarLabel = sidebarRow(labeled: "Taylor Client", in: app)
        XCTAssertTrue(sidebarLabel.waitForExistence(timeout: 5))
        sidebarLabel.tap()

        let generateButton = app.buttons["generate-report-button"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 10))
        generateButton.tap()

        let reportTitle = app.staticTexts["report-title"]
        XCTAssertTrue(reportTitle.waitForExistence(timeout: 5))

        let exportButton = app.buttons["report-export-button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        XCTAssertTrue(exportButton.isEnabled)
    }

    // MARK: - Bulk report generation

    /// Tapping "Generate All Reports" when the trial is expired must show the
    /// paywall, not attempt PDF generation.
    @MainActor
    func testExpiredTrialBlocksBulkReportGeneration() throws {
        let app = launchApp(environment: [
            "UITEST_SCENARIO": "expired_trial_with_client",
        ])

        XCTAssertTrue(sidebarRow(labeled: "Taylor Client", in: app).waitForExistence(timeout: 5))

        let generateButton = app.buttons["generate-all-reports-button"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        XCTAssertTrue(app.staticTexts["paywall-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["paywall-expired-banner"].waitForExistence(timeout: 5))
    }

    /// Tapping "Generate All Reports" during an active trial must complete PDF
    /// generation and surface a result. On macOS the folder picker is suppressed
    /// via UITEST_SKIP_FOLDER_PICKER so the result alert appears directly;
    /// on iPad a share sheet is presented.
    @MainActor
    func testBulkReportGenerationTriggersForActiveTrial() throws {
        let app = launchApp(environment: [
            "UITEST_SCENARIO": "active_trial_with_client",
            "UITEST_SKIP_FOLDER_PICKER": "1",
        ])

        XCTAssertTrue(sidebarRow(labeled: "Taylor Client", in: app).waitForExistence(timeout: 5))

        let generateButton = app.buttons["generate-all-reports-button"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

#if os(macOS)
        // Folder picker is skipped — result appears as an OK-dismissable dialog.
        // Query the OK button directly since SwiftUI .alert() container type varies by OS.
        let okButton = app.buttons["OK"].firstMatch
        XCTAssertTrue(okButton.waitForExistence(timeout: 15))
        okButton.tap()
#else
        // On iPad, a share sheet is presented with the generated PDFs.
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10))
#endif
    }

    // MARK: - Data export

    /// Settings must expose "Export All Clients (CSV)" when at least one client
    /// exists. Tapping it must trigger the system file-exporter.
    @MainActor
    func testDataExportAccessibleInSettings() throws {
        let app = launchApp(environment: [
            "UITEST_SCENARIO": "active_trial_with_client",
        ])

        XCTAssertTrue(sidebarRow(labeled: "Taylor Client", in: app).waitForExistence(timeout: 5))

        app.buttons["toolbar-settings"].tap()

        // Wait for the Settings sheet to appear.
        let exportButton = app.buttons["export-all-csv-button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        XCTAssertTrue(exportButton.isEnabled)

        exportButton.tap()

#if os(macOS)
        // NSSavePanel appears — dismiss it to avoid blocking further test runs.
        let savePanel = app.dialogs.firstMatch
        if !savePanel.waitForExistence(timeout: 5) {
            // Panel may have appeared and disappeared quickly.
        }
        app.typeKey(.escape, modifierFlags: [])
#else
        // On iPad, the system file exporter is presented as a sheet.
        let exportSheet = app.sheets.firstMatch
        XCTAssertTrue(exportSheet.waitForExistence(timeout: 5))
#endif
    }

    /// Returns the sidebar row element for the given client name.
    ///
    /// macOS NavigationSplitView sidebar List → NSOutlineView → XCUI `outline`.
    /// iPadOS 16+ List → UICollectionView → XCUI `cell` (not `table`).
    /// Using `app.cells.containing(...)` covers all iOS versions and both platforms
    /// without relying on a specific container type.
    private func sidebarRow(labeled label: String, in app: XCUIApplication) -> XCUIElement {
#if os(macOS)
        app.outlines.staticTexts[label].firstMatch
#else
        app.cells.containing(.staticText, identifier: label).firstMatch
#endif
    }

    private func launchApp(environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ApplePersistenceIgnoreState",
            "YES",
        ]
        app.launchEnvironment = environment
        app.launch()
        // Ensure the app window is front-most; xcodebuild CLI launches may
        // not activate the window automatically on macOS.
        app.activate()
        // If macOS restored the app with no windows, open a fresh main window.
        if !app.windows.firstMatch.waitForExistence(timeout: 10) {
            app.typeKey("n", modifierFlags: .command)
            _ = app.windows.firstMatch.waitForExistence(timeout: 5)
        }
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
