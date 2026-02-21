import Foundation

struct AnalyticsEvent: Codable {
    let name: String
    let timestamp: Date
    let properties: [String: String]
}

struct AnalyticsService {

    private static let storageKey = "healtheye_analytics_events"

    static func track(_ name: String, properties: [String: String] = [:]) {
        var events = allEvents()
        let event = AnalyticsEvent(name: name, timestamp: Date(), properties: properties)
        events.append(event)

        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func allEvents() -> [AnalyticsEvent] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let events = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) else {
            return []
        }
        return events
    }
}
