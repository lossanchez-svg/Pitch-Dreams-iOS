import XCTest
@testable import PitchDreams

@MainActor
final class AuthManagerTests: XCTestCase {

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

    // MARK: - Restore Session

    func testRestoreSessionEmptyKeychainSetsUnauthenticated() {
        sut.restoreSession()
        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(sut.currentUser)
    }

    // MARK: - Login Parent

    func testLoginParentSuccessSetsAuthenticated() async throws {
        let response = TestFixtures.makeTokenResponse()
        mockAPI.enqueue(response)

        try await sut.loginParent(email: "parent@example.com", password: "password123")

        if case .authenticated(let user) = sut.state {
            XCTAssertEqual(user.role, .parent)
        } else {
            XCTFail("Expected authenticated state")
        }
    }

    func testLoginParentFailureThrows() async {
        mockAPI.enqueueError(APIError.unauthorized)

        do {
            try await sut.loginParent(email: "bad@example.com", password: "wrong")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(sut.state, .loading) // Never got set to authenticated
        }
    }

    // MARK: - Logout

    func testLogoutClearsState() async throws {
        let response = TestFixtures.makeTokenResponse()
        mockAPI.enqueue(response)
        try await sut.loginParent(email: "parent@example.com", password: "password123")

        sut.logout()

        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(sut.currentUser)
    }
}
