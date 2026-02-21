import Foundation

enum AttentionBucket: String, CaseIterable, Codable {
    case low
    case medium
    case high

    static func from(score: Double) -> AttentionBucket {
        switch score {
        case 0..<40:
            return .low
        case 40..<70:
            return .medium
        default:
            return .high
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}
