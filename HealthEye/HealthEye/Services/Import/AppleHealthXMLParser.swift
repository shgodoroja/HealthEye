import Foundation

struct ParsedHealthData: Sendable {
    var dailyMetrics: [String: DailyAccumulator] = [:]
    var exportDate: Date?
    var totalRecordsParsed: Int = 0

    var dateRangeStart: Date? {
        dailyMetrics.values.compactMap(\.date).min()
    }

    var dateRangeEnd: Date? {
        dailyMetrics.values.compactMap(\.date).max()
    }
}

struct DailyAccumulator: Sendable {
    let dateString: String
    let date: Date
    var stepsSum: Double?
    var hrvValues: [Double] = []
    var restingHrLast: (value: Double, date: Date)?
    var sleepMinutesSum: Double?
    var workoutMinutesSum: Double?

    var hrvMean: Double? {
        guard !hrvValues.isEmpty else { return nil }
        return hrvValues.reduce(0, +) / Double(hrvValues.count)
    }
}

final class AppleHealthXMLParser: NSObject, XMLParserDelegate, @unchecked Sendable {
    private var parsedData = ParsedHealthData()
    private var recordCount = 0
    private let progressHandler: (@Sendable (Int) -> Void)?

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        return df
    }()

    private static let exportDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    private let relevantTypes: Set<String> = [
        "HKQuantityTypeIdentifierStepCount",
        "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
        "HKQuantityTypeIdentifierRestingHeartRate",
        "HKQuantityTypeIdentifierAppleExerciseTime",
        "HKCategoryTypeIdentifierSleepAnalysis",
    ]

    private let sleepAwakeValues: Set<String> = [
        "HKCategoryValueSleepAnalysisInBed",
        "HKCategoryValueSleepAnalysisAwake",
    ]

    init(progressHandler: (@Sendable (Int) -> Void)? = nil) {
        self.progressHandler = progressHandler
        super.init()
    }

    func parse(fileURL: URL) throws -> ParsedHealthData {
        guard let parser = XMLParser(contentsOf: fileURL) else {
            throw ImportError.invalidFile("Could not open XML file")
        }
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false

        guard parser.parse() else {
            if let error = parser.parserError {
                throw ImportError.parsingFailed(error.localizedDescription)
            }
            throw ImportError.parsingFailed("Unknown parsing error")
        }

        return parsedData
    }

    // MARK: - XMLParserDelegate

    nonisolated func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        switch elementName {
        case "ExportDate":
            if let dateStr = attributes["value"],
               let date = Self.exportDateFormatter.date(from: dateStr) {
                parsedData.exportDate = date
            }
        case "Record":
            processRecord(attributes: attributes)
        default:
            break
        }
    }

    nonisolated func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Error handled by parse() return value
    }

    // MARK: - Record Processing

    private func processRecord(attributes: [String: String]) {
        guard let type = attributes["type"], relevantTypes.contains(type) else { return }

        recordCount += 1
        if recordCount % 10_000 == 0 {
            progressHandler?(recordCount)
        }

        parsedData.totalRecordsParsed = recordCount

        switch type {
        case "HKQuantityTypeIdentifierStepCount":
            processSteps(attributes: attributes)
        case "HKQuantityTypeIdentifierHeartRateVariabilitySDNN":
            processHRV(attributes: attributes)
        case "HKQuantityTypeIdentifierRestingHeartRate":
            processRestingHR(attributes: attributes)
        case "HKQuantityTypeIdentifierAppleExerciseTime":
            processWorkout(attributes: attributes)
        case "HKCategoryTypeIdentifierSleepAnalysis":
            processSleep(attributes: attributes)
        default:
            break
        }
    }

    private func processSteps(attributes: [String: String]) {
        guard let dateStr = attributes["startDate"],
              let date = Self.dateFormatter.date(from: dateStr),
              let valueStr = attributes["value"],
              let value = Double(valueStr) else { return }

        let dayKey = Self.dayFormatter.string(from: date)
        ensureAccumulator(for: dayKey, date: date)
        parsedData.dailyMetrics[dayKey]!.stepsSum = (parsedData.dailyMetrics[dayKey]!.stepsSum ?? 0) + value
    }

    private func processHRV(attributes: [String: String]) {
        guard let dateStr = attributes["startDate"],
              let date = Self.dateFormatter.date(from: dateStr),
              let valueStr = attributes["value"],
              let value = Double(valueStr) else { return }

        let dayKey = Self.dayFormatter.string(from: date)
        ensureAccumulator(for: dayKey, date: date)
        parsedData.dailyMetrics[dayKey]!.hrvValues.append(value)
    }

    private func processRestingHR(attributes: [String: String]) {
        guard let dateStr = attributes["startDate"],
              let date = Self.dateFormatter.date(from: dateStr),
              let valueStr = attributes["value"],
              let value = Double(valueStr) else { return }

        let dayKey = Self.dayFormatter.string(from: date)
        ensureAccumulator(for: dayKey, date: date)

        if let existing = parsedData.dailyMetrics[dayKey]!.restingHrLast {
            if date > existing.date {
                parsedData.dailyMetrics[dayKey]!.restingHrLast = (value, date)
            }
        } else {
            parsedData.dailyMetrics[dayKey]!.restingHrLast = (value, date)
        }
    }

    private func processWorkout(attributes: [String: String]) {
        guard let dateStr = attributes["startDate"],
              let date = Self.dateFormatter.date(from: dateStr),
              let valueStr = attributes["value"],
              let value = Double(valueStr) else { return }

        let dayKey = Self.dayFormatter.string(from: date)
        ensureAccumulator(for: dayKey, date: date)
        parsedData.dailyMetrics[dayKey]!.workoutMinutesSum = (parsedData.dailyMetrics[dayKey]!.workoutMinutesSum ?? 0) + value
    }

    private func processSleep(attributes: [String: String]) {
        // Exclude InBed and Awake — only count Core, Deep, REM
        if let sleepValue = attributes["value"], sleepAwakeValues.contains(sleepValue) {
            return
        }

        guard let startStr = attributes["startDate"],
              let endStr = attributes["endDate"],
              let startDate = Self.dateFormatter.date(from: startStr),
              let endDate = Self.dateFormatter.date(from: endStr) else { return }

        let durationMinutes = endDate.timeIntervalSince(startDate) / 60.0
        guard durationMinutes > 0 else { return }

        // Assign to endDate's day (sleep that crosses midnight belongs to wake-up day)
        let dayKey = Self.dayFormatter.string(from: endDate)
        ensureAccumulator(for: dayKey, date: endDate)
        parsedData.dailyMetrics[dayKey]!.sleepMinutesSum = (parsedData.dailyMetrics[dayKey]!.sleepMinutesSum ?? 0) + durationMinutes
    }

    private func ensureAccumulator(for dayKey: String, date: Date) {
        if parsedData.dailyMetrics[dayKey] == nil {
            let calendar = Calendar(identifier: .gregorian)
            let startOfDay = calendar.startOfDay(for: date)
            parsedData.dailyMetrics[dayKey] = DailyAccumulator(dateString: dayKey, date: startOfDay)
        }
    }
}

enum ImportError: LocalizedError, Equatable {
    case invalidFile(String)
    case parsingFailed(String)
    case duplicateImport(String)
    case saveFailed(String)
    case zipExtractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFile(let msg): return "Invalid file: \(msg)"
        case .parsingFailed(let msg): return "Parsing failed: \(msg)"
        case .duplicateImport(let msg): return "Duplicate import: \(msg)"
        case .saveFailed(let msg): return "Save failed: \(msg)"
        case .zipExtractionFailed(let msg): return "Zip extraction failed: \(msg)"
        }
    }
}
