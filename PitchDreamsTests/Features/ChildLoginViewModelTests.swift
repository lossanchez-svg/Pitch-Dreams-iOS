import XCTest
@testable import PitchDreams

@MainActor
final class ChildLoginViewModelTests: XCTestCase {

    private var sut: ChildLoginViewModel!
    private var mockAPI: MockAPIClient!
    private var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        authManager = AuthManager(apiClient: mockAPI, keychain: MockKeychainService())
        sut = ChildLoginViewModel(authManager: authManager)
    }

    // MARK: - Validation

    func testIsValidShortPinReturnsFalse() {
        sut.parentEmail = "parent@example.com"
        sut.nickname = "TestKid"
        sut.pin = "12"
        XCTAssertFalse(sut.isValid)
    }

    func testIsValidEmptyNicknameReturnsFalse() {
        sut.parentEmail = "parent@example.com"
        sut.nickname = ""
        sut.pin = "1234"
        XCTAssertFalse(sut.isValid)
    }

    func testIsValidValidInputsReturnsTrue() {
        sut.parentEmail = "parent@example.com"
        sut.nickname = "TestKid"
        sut.pin = "1234"
        XCTAssertTrue(sut.isValid)
    }

    func testIsValidEmptyEmailReturnsFalse() {
        sut.parentEmail = ""
        sut.nickname = "TestKid"
        sut.pin = "1234"
        XCTAssertFalse(sut.isValid)
    }

    func testIsValidNonNumericPinReturnsFalse() {
        sut.parentEmail = "parent@example.com"
        sut.nickname = "TestKid"
        sut.pin = "abcd"
        XCTAssertFalse(sut.isValid)
    }
}
