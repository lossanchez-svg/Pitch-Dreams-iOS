import XCTest
@testable import PitchDreams

@MainActor
final class ChildLoginViewModelTests: XCTestCase {

    private var sut: ChildLoginViewModel!
    private var mockAPI: MockAPIClient!
    private var mockKeychain: MockKeychainService!
    private var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        mockKeychain = MockKeychainService()
        authManager = AuthManager(apiClient: mockAPI, keychainService: mockKeychain)
        sut = ChildLoginViewModel(authManager: authManager)
    }

    override func tearDown() {
        sut = nil
        authManager = nil
        mockAPI = nil
        mockKeychain = nil
        super.tearDown()
    }

    // MARK: - Validation

    func testIsValid_shortPin_returnsFalse() {
        sut.parentEmail = "parent@example.com"
        sut.childNickname = "TestKid"
        sut.pin = "12"

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_emptyNickname_returnsFalse() {
        sut.parentEmail = "parent@example.com"
        sut.childNickname = ""
        sut.pin = "1234"

        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_validInputs_returnsTrue() {
        sut.parentEmail = "parent@example.com"
        sut.childNickname = "TestKid"
        sut.pin = "1234"

        XCTAssertTrue(sut.isValid)
    }

    func testIsValid_emptyParentEmail_returnsFalse() {
        sut.parentEmail = ""
        sut.childNickname = "TestKid"
        sut.pin = "1234"

        XCTAssertFalse(sut.isValid)
    }
}
