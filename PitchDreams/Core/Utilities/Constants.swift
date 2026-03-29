import Foundation

enum Constants {
    static let baseURL = URL(string: "https://www.pitchdreams.soccer")!
    static let apiBasePath = "/api/v1"

    enum Keychain {
        static let service = "com.pitchdreams.training"
        static let tokenKey = "auth_token"
        static let userKey = "auth_user"
    }
}
