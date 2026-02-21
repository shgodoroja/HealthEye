import Foundation

enum ExportFormat {
    case csv
    case json
}

struct DataExportService {

    // MARK: - Single Client Export

    static func exportClient(_ client: Client, format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            return try exportClientCSV(client)
        case .json:
            return try exportClientJSON(client)
        }
    }

    // MARK: - All Clients Export

    static func exportAllClients(_ clients: [Client], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            return try exportAllClientsCSV(clients)
        case .json:
            return try exportAllClientsJSON(clients)
        }
    }

    // MARK: - CSV

    private static let csvHeader = "client,date,sleepMinutes,hrvMs,restingHrBpm,workoutMinutes,steps"

    private static func exportClientCSV(_ client: Client) throws -> Data {
        var lines = [csvHeader]
        let sortedMetrics = client.metrics.sorted { $0.date < $1.date }

        for metric in sortedMetrics {
            lines.append(csvRow(clientName: client.displayName, metric: metric))
        }

        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }

    private static func exportAllClientsCSV(_ clients: [Client]) throws -> Data {
        var lines = [csvHeader]

        for client in clients.sorted(by: { $0.displayName < $1.displayName }) {
            let sortedMetrics = client.metrics.sorted { $0.date < $1.date }
            for metric in sortedMetrics {
                lines.append(csvRow(clientName: client.displayName, metric: metric))
            }
        }

        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }

    private static func csvRow(clientName: String, metric: MetricDaily) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let escapedName = clientName.contains(",") ? "\"\(clientName)\"" : clientName

        let fields: [String] = [
            escapedName,
            formatter.string(from: metric.date),
            metric.sleepMinutes.map { String($0) } ?? "",
            metric.hrvMs.map { String($0) } ?? "",
            metric.restingHrBpm.map { String($0) } ?? "",
            metric.workoutMinutes.map { String($0) } ?? "",
            metric.steps.map { String($0) } ?? "",
        ]

        return fields.joined(separator: ",")
    }

    // MARK: - JSON

    private struct ClientExportJSON: Codable {
        let displayName: String
        let timezone: String
        let createdAt: Date
        let metrics: [MetricJSON]
    }

    private struct MetricJSON: Codable {
        let date: Date
        let sleepMinutes: Double?
        let hrvMs: Double?
        let restingHrBpm: Double?
        let workoutMinutes: Double?
        let steps: Double?
    }

    private static func exportClientJSON(_ client: Client) throws -> Data {
        let export = clientToJSON(client)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    private static func exportAllClientsJSON(_ clients: [Client]) throws -> Data {
        let exports = clients
            .sorted { $0.displayName < $1.displayName }
            .map { clientToJSON($0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exports)
    }

    private static func clientToJSON(_ client: Client) -> ClientExportJSON {
        let sortedMetrics = client.metrics.sorted { $0.date < $1.date }
        return ClientExportJSON(
            displayName: client.displayName,
            timezone: client.timezone,
            createdAt: client.createdAt,
            metrics: sortedMetrics.map { m in
                MetricJSON(
                    date: m.date,
                    sleepMinutes: m.sleepMinutes,
                    hrvMs: m.hrvMs,
                    restingHrBpm: m.restingHrBpm,
                    workoutMinutes: m.workoutMinutes,
                    steps: m.steps
                )
            }
        )
    }

    enum ExportError: LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode export data."
            }
        }
    }
}
