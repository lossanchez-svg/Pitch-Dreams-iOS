import Foundation

struct ArcState: Codable, Identifiable {
    let id: String
    let arcId: String
    let status: String
    let dayIndex: Int
    let sessionsCompleted: Int
}

struct ArcSuggestion: Codable {
    let arcId: String
    let reason: String
}

struct ArcProgressResult: Codable {
    let arcCompleted: Bool
    let completionMessage: String?
    let arcId: String?
}
