import Foundation

enum Constants {
    static let baseURL = URL(string: "https://www.pitchdreams.soccer")!
    static let apiBasePath = "/api/v1"

    enum Keychain {
        static let service = "com.pitchdreams.training"
        static let tokenKey = "auth_token"
        static let userKey = "auth_user"
    }

    /// Legal pages hosted by the web app. Apple requires functional Terms and
    /// Privacy links anywhere a subscription is offered (Guideline 3.1.2).
    enum Legal {
        static let privacyPolicy = URL(string: "https://pitchdreams.soccer/privacy")!
        static let termsOfService = URL(string: "https://pitchdreams.soccer/terms")!
        static let kidsPrivacy = URL(string: "https://pitchdreams.soccer/kids-privacy")!
    }
}
