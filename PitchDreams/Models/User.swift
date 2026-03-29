import Foundation

struct ChildProfile: Codable, Identifiable {
    let id: String
    let nickname: String
    let age: Int
    let position: String?
    let avatarId: String?
    let avatarColor: String?
}

struct ChildSummary: Codable, Identifiable {
    let id: String
    let nickname: String
    let age: Int
    let position: String?
}

struct ChildProfileDetail: Codable {
    let nickname: String
    let avatarId: String
    let skipAnimations: Bool
    let voiceEnabled: Bool
}
