import XCTest
@testable import PitchDreams

@MainActor
final class AuthManagerEdgeCaseTests: XCTestCase {

    private var sut: AuthManager!
    private var mockAPI: MockAPIClient!
    private var mockKeychain: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        mockKeychain = MockKeychainService()
        sut = AuthManager(apiClient: mockAPI, keychain: mockKeychain)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockKeychain = nil
        super.tearDown()
    }

    // MARK: - 401 Handling

    func testHandleUnauthorizedClearsKeychainToken() {
        // Pre-populate keychain
        try! mockKeychain.save(value: "old-jwt-token", for: Constants.Keychain.tokenKey)
        try! mockKeychain.save(value: "{}", for: Constants.Keychain.userKey)

        sut.handleUnauthorized()

        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.userKey))
    }

    func testHandleUnauthorizedSetsUnauthenticated() {
        sut.handleUnauthorized()
        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(sut.currentUser)
    }

    func testHandleUnauthorizedAfterAuthenticated() async throws {
        // Login first
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .parent))
        try await sut.loginParent(email: "parent@test.com", password: "pass")
        XCTAssertNotNil(sut.currentUser)

        // Simulate 401
        sut.handleUnauthorized()

        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
    }

    // MARK: - Restore Session Edge Cases

    func testRestoreSessionWithEmptyTokenString() {
        try! mockKeychain.save(value: "", for: Constants.Keychain.tokenKey)
        try! mockKeychain.save(value: "{}", for: Constants.Keychain.userKey)

        sut.restoreSession()

        XCTAssertEqual(sut.state, .unauthenticated)
    }

    func testRestoreSessionWithMissingUserJson() {
        try! mockKeychain.save(value: "valid-token", for: Constants.Keychain.tokenKey)
        // No user key saved

        sut.restoreSession()

        XCTAssertEqual(sut.state, .unauthenticated)
    }

    func testRestoreSessionWithCorruptedUserJson() {
        try! mockKeychain.save(value: "valid-token", for: Constants.Keychain.tokenKey)
        try! mockKeychain.save(value: "not-valid-json{{{", for: Constants.Keychain.userKey)

        sut.restoreSession()

        XCTAssertEqual(sut.state, .unauthenticated)
    }

    func testRestoreSessionWithPartialUserJson() {
        try! mockKeychain.save(value: "valid-token", for: Constants.Keychain.tokenKey)
        // Missing required fields
        try! mockKeychain.save(value: "{\"id\": \"abc\"}", for: Constants.Keychain.userKey)

        sut.restoreSession()

        XCTAssertEqual(sut.state, .unauthenticated)
    }

    func testRestoreSessionWithValidData() {
        let user = TestFixtures.makeAuthenticatedUser(role: .child, id: "child-123", childId: "child-123")
        let encoder = JSONEncoder()
        let userData = try! encoder.encode(user)
        let userJson = String(data: userData, encoding: .utf8)!

        try! mockKeychain.save(value: "valid-token-abc", for: Constants.Keychain.tokenKey)
        try! mockKeychain.save(value: userJson, for: Constants.Keychain.userKey)

        sut.restoreSession()

        if case .authenticated(let restored) = sut.state {
            XCTAssertEqual(restored.id, "child-123")
            XCTAssertEqual(restored.role, .child)
        } else {
            XCTFail("Expected authenticated state")
        }
    }

    // MARK: - Login Failure Does Not Persist

    func testLoginParentFailureDoesNotPersistToken() async {
        mockAPI.enqueueError(APIError.unauthorized)

        do {
            try await sut.loginParent(email: "bad@test.com", password: "wrong")
            XCTFail("Expected error")
        } catch {}

        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.userKey))
    }

    func testLoginChildFailureDoesNotPersistToken() async {
        mockAPI.enqueueError(APIError.server("Invalid PIN"))

        do {
            try await sut.loginChild(parentEmail: "p@test.com", nickname: "Kid", pin: "0000")
            XCTFail("Expected error")
        } catch {}

        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.userKey))
    }

    // MARK: - Logout Clears Keychain

    func testLogoutClearsKeychainCompletely() async throws {
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .parent))
        try await sut.loginParent(email: "parent@test.com", password: "pass")

        // Verify keychain has data
        XCTAssertNotNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
        XCTAssertNotNil(mockKeychain.retrieve(for: Constants.Keychain.userKey))

        sut.logout()

        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.userKey))
        XCTAssertEqual(sut.state, .unauthenticated)
    }

    // MARK: - Concurrent Login

    func testSequentialLoginsOverwriteState() async throws {
        // First login as parent
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .parent, token: "parent-token"))
        try await sut.loginParent(email: "parent@test.com", password: "pass")
        XCTAssertEqual(sut.currentUser?.role, .parent)

        // Then login as child (same session — shouldn't happen in production but tests state)
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .child, token: "child-token"))
        try await sut.loginChild(parentEmail: "parent@test.com", nickname: "Kid", pin: "1111")

        // State reflects latest login
        XCTAssertEqual(sut.currentUser?.role, .child)
        XCTAssertEqual(mockKeychain.retrieve(for: Constants.Keychain.tokenKey), "child-token")
    }

    // MARK: - Signup + Auto-Login

    func testSignupFailureDoesNotPersist() async {
        mockAPI.enqueueError(APIError.server("Email taken"))

        do {
            try await sut.signup(email: "taken@test.com", password: "pass")
            XCTFail("Expected error")
        } catch {}

        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
        XCTAssertNotEqual(sut.state, .unauthenticated) // stays .loading since never set
    }

    func testSignupSuccessThenAutoLogin() async throws {
        // Signup response
        mockAPI.enqueue(SignupResponse(success: true, parentId: "new-parent-id"))
        // Auto-login response
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .parent, token: "new-token"))

        try await sut.signup(email: "new@test.com", password: "Secure1!")

        XCTAssertEqual(sut.currentUser?.role, .parent)
        XCTAssertEqual(mockKeychain.retrieve(for: Constants.Keychain.tokenKey), "new-token")
    }

    // MARK: - Multiple handleUnauthorized Calls

    func testMultipleUnauthorizedCallsAreIdempotent() async throws {
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .parent))
        try await sut.loginParent(email: "parent@test.com", password: "pass")

        sut.handleUnauthorized()
        sut.handleUnauthorized()
        sut.handleUnauthorized()

        // Still unauthenticated, no crash
        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(mockKeychain.retrieve(for: Constants.Keychain.tokenKey))
    }

    // MARK: - currentUser Computed Property

    func testCurrentUserNilWhenLoading() {
        XCTAssertEqual(sut.state, .loading)
        XCTAssertNil(sut.currentUser)
    }

    func testCurrentUserNilWhenUnauthenticated() {
        sut.handleUnauthorized()
        XCTAssertNil(sut.currentUser)
    }

    func testCurrentUserPopulatedWhenAuthenticated() async throws {
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .child, token: "t"))
        try await sut.loginChild(parentEmail: "p@test.com", nickname: "Kid", pin: "1111")
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.role, .child)
    }
}
