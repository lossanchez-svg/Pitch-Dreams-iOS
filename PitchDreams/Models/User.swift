import Foundation

struct ChildProfile: Codable, Identifiable {
    let id: String
    let nickname: String
    let age: Int
    let position: String?
    let avatarId: String?
    let avatarColor: String?
}

struct ChildSummary: Codable, Identifiable, Hashable {
    let id: String
    let nickname: String
    let age: Int
    let position: String?
    let avatarId: String?

    init(id: String, nickname: String, age: Int, position: String? = nil, avatarId: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.age = age
        self.position = position
        self.avatarId = avatarId
    }
}

struct ChildProfileDetail: Codable {
    let nickname: String
    let avatarId: String
    let skipAnimations: Bool
    let voiceEnabled: Bool
}
