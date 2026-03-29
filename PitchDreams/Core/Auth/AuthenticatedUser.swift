import Foundation

enum UserRole: String, Codable {
    case parent
    case child
}

struct AuthenticatedUser: Codable, Equatable {
    let id: String
    let role: UserRole
    let email: String?
    let name: String?
    let childId: String?
    let parentId: String?

    var isParent: Bool { role == .parent }
    var isChild: Bool { role == .child }
    var effectiveChildId: String? { childId ?? (role == .child ? id : nil) }
}

struct TokenResponse: Decodable {
    let token: String
    let user: AuthenticatedUser
}
