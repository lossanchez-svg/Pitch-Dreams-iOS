import XCTest
@testable import PitchDreams

@MainActor
final class ParentLoginViewModelTests: XCTestCase {

    private var sut: ParentLoginViewModel!
    private var mockAPI: MockAPIClient!
    private var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        authManager = AuthManager(apiClient: mockAPI, keychain: MockKeychainService())
        sut = ParentLoginViewModel(authManager: authManager)
    }

    // MARK: - Validation

    func testIsValidEmptyEmailReturnsFalse() {
        sut.email = ""
        sut.password = "password123"
        XCTAssertFalse(sut.isValid)
    }

    func testIsValidEmptyPasswordReturnsFalse() {
        sut.email = "test@example.com"
        sut.password = ""
        XCTAssertFalse(sut.isValid)
    }

    func testIsValidShortPasswordReturnsFalse() {
        sut.email = "test@example.com"
        sut.password = "short"
        XCTAssertFalse(sut.isValid)
    }

    func testIsValidValidInputReturnsTrue() {
        sut.email = "test@example.com"
        sut.password = "password123"
        XCTAssertTrue(sut.isValid)
    }

    // MARK: - Login

    func testLoginSuccessNoError() async {
        mockAPI.enqueue(TestFixtures.makeTokenResponse())
        sut.email = "parent@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoginFailureSetsError() async {
        mockAPI.enqueueError(APIError.unauthorized)
        sut.email = "bad@example.com"
        sut.password = "wrong"

        await sut.login()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }
}
