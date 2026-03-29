import XCTest
@testable import PitchDreams

@MainActor
final class ParentLoginViewModelTests: XCTestCase {

    private var sut: ParentLoginViewModel!
    private var mockAPI: MockAPIClient!
    private var mockKeychain: MockKeychainService!
    private var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        mockKeychain = MockKeychainService()
        authManager = AuthManager(apiClient: mockAPI, keychainService: mockKeychain)
        sut = ParentLoginViewModel(authManager: authManager)
    }

    override func tearDown() {
        sut = nil
        authManager = nil
        mockAPI = nil
        mockKeychain = nil
        super.tearDown()
    }

    // MARK: - Validation

    func testIsValid_emptyEmail_returnsFalse() {
        sut.email = ""
        sut.password = "password123"

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_emptyPassword_returnsFalse() {
        sut.email = "test@example.com"
        sut.password = ""

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_validEmailAndPassword_returnsTrue() {
        sut.email = "test@example.com"
        sut.password = "password123"

        XCTAssertTrue(sut.isValid)
    }

    // MARK: - Login

    func testLogin_success_noError() async {
        let tokenResponse = TestFixtures.tokenResponse()
        mockAPI.mockResult = tokenResponse
        sut.email = "parent@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_failure_setsError() async {
        mockAPI.mockError = APIError.unauthorized
        sut.email = "bad@example.com"
        sut.password = "wrong"

        await sut.login()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }
}
