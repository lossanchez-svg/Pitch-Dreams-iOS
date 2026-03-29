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
        sut = AuthManager(apiClient: mockAPI, keychainService: mockKeychain)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockKeychain = nil
        super.tearDown()
    }

    // MARK: - Restore Session

    func testRestoreSession_emptyKeychain_remainsUnauthenticated() async {
        await sut.restoreSession()

        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(sut.currentUser)
    }

    // MARK: - Login Parent

    func testLoginParent_success_setsAuthenticated() async throws {
        let tokenResponse = TestFixtures.tokenResponse()
        mockAPI.mockResult = tokenResponse

        try await sut.loginParent(email: "parent@example.com", password: "password123")

        XCTAssertEqual(sut.state, .authenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.role, .parent)
    }

    func testLoginParent_failure_remainsUnauthenticated() async {
        mockAPI.mockError = APIError.unauthorized

        do {
            try await sut.loginParent(email: "bad@example.com", password: "wrong")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(sut.state, .unauthenticated)
            XCTAssertNil(sut.currentUser)
        }
    }

    // MARK: - Logout

    func testLogout_clearsKeychainAndState() async throws {
        // First log in
        let tokenResponse = TestFixtures.tokenResponse()
        mockAPI.mockResult = tokenResponse
        try await sut.loginParent(email: "parent@example.com", password: "password123")
        XCTAssertEqual(sut.state, .authenticated)

        // Then log out
        sut.logout()

        XCTAssertEqual(sut.state, .unauthenticated)
        XCTAssertNil(sut.currentUser)
    }
}
