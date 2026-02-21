import Foundation

enum AccountStatus: String, Codable, CaseIterable {
    case active
    case expired
    case pastDue = "past_due"
}
