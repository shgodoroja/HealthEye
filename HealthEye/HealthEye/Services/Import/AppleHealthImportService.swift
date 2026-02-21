import Foundation
import SwiftData

enum ImportState: Equatable {
    case idle
    case validating
    case checkingDuplicate
    case parsing(progress: Int)
    case saving
    case completed(ImportSummary)
    case failed(String)
}

struct ImportSummary: Equatable {
    let totalDays: Int
    let dateRangeStart: Date?
    let dateRangeEnd: Date?
    let totalRecordsParsed: Int
    let metricsBreakdown: MetricsBreakdown
}

struct MetricsBreakdown: Equatable {
    let daysWithSleep: Int
    let daysWithHRV: Int
    let daysWithRestingHR: Int
    let daysWithWorkout: Int
    let daysWithSteps: Int
}

@Observable
final class AppleHealthImportService {
    var state: ImportState = .idle

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func importFile(_ fileURL: URL, for client: Client) async {
        state = .validating

        do {
            // Step 1: Extract XML
            let xmlURL = try ZipExtractor.extractExportXML(from: fileURL)

            // Step 2: Hash the XML file
            let fileHash = try FileHasher.sha256Hash(of: xmlURL)

            // Step 3: Check for duplicates
            state = .checkingDuplicate
            let isDuplicate = try await checkDuplicate(fileHash: fileHash, clientID: client.id)
            if isDuplicate {
                state = .failed("This file has already been imported for this client.")
                return
            }

            // Step 4: Parse
            state = .parsing(progress: 0)
            let parser = AppleHealthXMLParser { [weak self] count in
                Task { @MainActor in
                    self?.state = .parsing(progress: count)
                }
            }
            let parsedData = try parser.parse(fileURL: xmlURL)

            guard !parsedData.dailyMetrics.isEmpty else {
                state = .failed("No health data found in the file.")
                return
            }

            // Step 5: Save
            state = .saving
            let summary = try await saveMetrics(
                parsedData: parsedData,
                fileHash: fileHash,
                client: client
            )

            state = .completed(summary)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func checkDuplicate(fileHash: String, clientID: UUID) async throws -> Bool {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ClientImport>(
            predicate: #Predicate<ClientImport> { record in
                record.fileHash == fileHash
            }
        )
        let existing = try context.fetch(descriptor)
        return existing.contains { $0.client?.id == clientID }
    }

    private func saveMetrics(
        parsedData: ParsedHealthData,
        fileHash: String,
        client: Client
    ) async throws -> ImportSummary {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false

        do {
            // Fetch the client in this context
            let clientID = client.id
            let clientDescriptor = FetchDescriptor<Client>(
                predicate: #Predicate<Client> { c in c.id == clientID }
            )
            guard let localClient = try context.fetch(clientDescriptor).first else {
                throw ImportError.saveFailed("Client not found")
            }

            var daysWithSleep = 0
            var daysWithHRV = 0
            var daysWithRestingHR = 0
            var daysWithWorkout = 0
            var daysWithSteps = 0

            for (_, accumulator) in parsedData.dailyMetrics {
                let date = accumulator.date

                // Upsert: check existing MetricDaily for this client+date
                let existingDescriptor = FetchDescriptor<MetricDaily>(
                    predicate: #Predicate<MetricDaily> { m in
                        m.client?.id == clientID && m.date == date
                    }
                )
                let existing = try context.fetch(existingDescriptor).first

                let metric: MetricDaily
                if let existing {
                    metric = existing
                } else {
                    metric = MetricDaily(client: localClient, date: date)
                    context.insert(metric)
                }

                if let steps = accumulator.stepsSum {
                    metric.steps = steps
                    daysWithSteps += 1
                }
                if let hrv = accumulator.hrvMean {
                    metric.hrvMs = hrv
                    daysWithHRV += 1
                }
                if let restingHr = accumulator.restingHrLast {
                    metric.restingHrBpm = restingHr.value
                    daysWithRestingHR += 1
                }
                if let workout = accumulator.workoutMinutesSum {
                    metric.workoutMinutes = workout
                    daysWithWorkout += 1
                }
                if let sleep = accumulator.sleepMinutesSum {
                    metric.sleepMinutes = sleep
                    daysWithSleep += 1
                }
            }

            // Create import record
            let importRecord = ClientImport(
                client: localClient,
                fileHash: fileHash,
                dateRangeStart: parsedData.dateRangeStart,
                dateRangeEnd: parsedData.dateRangeEnd,
                importStatus: .success
            )
            context.insert(importRecord)

            try context.save()

            let breakdown = MetricsBreakdown(
                daysWithSleep: daysWithSleep,
                daysWithHRV: daysWithHRV,
                daysWithRestingHR: daysWithRestingHR,
                daysWithWorkout: daysWithWorkout,
                daysWithSteps: daysWithSteps
            )

            return ImportSummary(
                totalDays: parsedData.dailyMetrics.count,
                dateRangeStart: parsedData.dateRangeStart,
                dateRangeEnd: parsedData.dateRangeEnd,
                totalRecordsParsed: parsedData.totalRecordsParsed,
                metricsBreakdown: breakdown
            )
        } catch {
            context.rollback()
            throw ImportError.saveFailed(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }
}
