import Foundation

struct AnalyticsEvent: Codable {
    let name: String
    let timestamp: Date
    let properties: [String: String]
}

struct AnalyticsService {

    private static let storageKey = "healtheye_analytics_events"
    private static let maxEvents = 10_000

    /// Track an event with raw properties.
    static func track(_ name: String, properties: [String: String] = [:]) {
        var events = allEvents()
        let event = AnalyticsEvent(name: name, timestamp: Date(), properties: properties)
        events.append(event)

        // Keep only the most recent events to prevent unbounded growth
        if events.count > maxEvents {
            events = Array(events.suffix(maxEvents))
        }

        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Track an event enriched with standard account dimensions: `plan_type` and
    /// `trial_day` (days since trial started, or "n/a" when account is nil or on a
    /// paid plan). Extra properties are merged on top — they take precedence over
    /// the standard dimensions if there is a key conflict.
    static func track(
        _ name: String,
        account: CoachAccount?,
        extra: [String: String] = [:]
    ) {
        var props = standardDimensions(for: account)
        for (key, value) in extra { props[key] = value }
        track(name, properties: props)
    }

    // MARK: - Helpers

    static func allEvents() -> [AnalyticsEvent] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let events = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) else {
            return []
        }
        return events
    }

    // MARK: - Private

    private static func standardDimensions(for account: CoachAccount?) -> [String: String] {
        guard let account else {
            return ["plan_type": "unknown", "trial_day": "unknown"]
        }
        let planType = account.planType.rawValue
        let trialDay: String
        if account.planType == .trial, let startAt = account.trialStartAt {
            let days = Calendar.current.dateComponents([.day], from: startAt, to: Date()).day ?? 0
            trialDay = String(max(1, days + 1))  // day 1 on the start date
        } else {
            trialDay = "n/a"
        }
        return ["plan_type": planType, "trial_day": trialDay]
    }
}
