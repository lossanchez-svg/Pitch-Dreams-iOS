import Foundation

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(AuthenticatedUser)
}

@MainActor
final class AuthManager: ObservableObject {
    @Published var state: AuthState = .loading

    /// Set when a 401 forces logout so the login screen can explain why.
    @Published var sessionExpired = false

    private let apiClient: APIClientProtocol
    private let keychain: KeychainServiceProtocol
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    var currentUser: AuthenticatedUser? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    init(apiClient: APIClientProtocol = APIClient.shared, keychain: KeychainServiceProtocol = KeychainService()) {
        self.apiClient = apiClient
        self.keychain = keychain

        // Wire up 401 auto-logout on the injected client. Production always
        // injects APIClient.shared (the default), which every ViewModel also
        // uses — so a 401 from any screen lands here.
        if let concreteClient = apiClient as? APIClient {
            concreteClient.onUnauthorized = { [weak self] in
                Task { @MainActor in
                    self?.handleUnauthorized()
                }
            }
        }
    }

    func restoreSession() {
        guard let tokenString = keychain.retrieve(for: Constants.Keychain.tokenKey),
              !tokenString.isEmpty,
              let userJson = keychain.retrieve(for: Constants.Keychain.userKey),
              let userData = userJson.data(using: .utf8),
              let user = try? decoder.decode(AuthenticatedUser.self, from: userData) else {
            state = .unauthenticated
            return
        }

        state = .authenticated(user)

        // Keep activeChildId current so CoachPersonality.current works on app relaunch
        if user.isChild, let childId = user.effectiveChildId {
            UserDefaults.standard.set(childId, forKey: "activeChildId")
        }

        Log.auth.info("Session restored for \(user.role.rawValue) \(user.id)")
    }

    func signup(email: String, password: String) async throws {
        let _: SignupResponse = try await apiClient.request(
            APIRouter.signup(email: email, password: password)
        )
        // Auto-login after signup
        try await loginParent(email: email, password: password)
        Log.auth.info("Signup + login complete")
    }

    func loginParent(email: String, password: String) async throws {
        let response: TokenResponse = try await apiClient.request(
            APIRouter.parentLogin(email: email, password: password)
        )
        try persistSession(token: response.token, user: response.user)
        sessionExpired = false
        state = .authenticated(response.user)
        Log.auth.info("Parent logged in: \(response.user.id)")
    }

    func loginChild(parentEmail: String, nickname: String, pin: String) async throws {
        let response: TokenResponse = try await apiClient.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: nickname, pin: pin)
        )
        try persistSession(token: response.token, user: response.user)
        sessionExpired = false
        state = .authenticated(response.user)

        // Set activeChildId so CoachPersonality.current reads the right per-child setting
        if let childId = response.user.effectiveChildId {
            UserDefaults.standard.set(childId, forKey: "activeChildId")
        }

        Log.auth.info("Child logged in: \(response.user.id)")
    }

    func logout() {
        clearSession()
        state = .unauthenticated
        Log.auth.info("Logged out")
    }

    func handleUnauthorized() {
        // Only flag expiry when there was a session to lose; a 401 from a bad
        // login attempt shouldn't show the "session expired" banner.
        if case .authenticated = state {
            sessionExpired = true
        }
        clearSession()
        state = .unauthenticated
        Log.auth.warning("Session expired — logged out")
    }

    // MARK: - Private

    private func persistSession(token: String, user: AuthenticatedUser) throws {
        try keychain.save(value: token, for: Constants.Keychain.tokenKey)
        let userData = try encoder.encode(user)
        if let userJson = String(data: userData, encoding: .utf8) {
            try keychain.save(value: userJson, for: Constants.Keychain.userKey)
        }
    }

    private func clearSession() {
        try? keychain.delete(for: Constants.Keychain.tokenKey)
        try? keychain.delete(for: Constants.Keychain.userKey)
    }
}
