import XCTest
@testable import PitchDreams

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var mockKeychain: MockKeychainService!
    var authManager: AuthManager!
    var viewModel: OnboardingViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        mockKeychain = MockKeychainService()
        authManager = AuthManager(apiClient: mockAPI, keychain: mockKeychain)
        viewModel = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
    }

    // MARK: - Step Navigation

    func testStepNavigation() {
        XCTAssertEqual(viewModel.step, 0)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.step, 1)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.step, 2)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.step, 3)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.step, 4)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.step, 4) // Max at 4 (5 steps: 0-4)
    }

    func testPreviousStepNavigation() {
        viewModel.nextStep()
        viewModel.nextStep()
        XCTAssertEqual(viewModel.step, 2)
        viewModel.previousStep()
        XCTAssertEqual(viewModel.step, 1)
        viewModel.previousStep()
        XCTAssertEqual(viewModel.step, 0)
        viewModel.previousStep()
        XCTAssertEqual(viewModel.step, 0) // Min at 0
    }

    // MARK: - Signup Validation

    func testSignupValidationAllFieldsRequired() {
        XCTAssertFalse(viewModel.isSignupValid)

        viewModel.email = "test@example.com"
        XCTAssertFalse(viewModel.isSignupValid)

        viewModel.password = "Password123"
        XCTAssertFalse(viewModel.isSignupValid) // confirmPassword mismatch

        viewModel.confirmPassword = "Password123"
        XCTAssertFalse(viewModel.isSignupValid) // Terms not agreed

        viewModel.agreedToTerms = true
        XCTAssertTrue(viewModel.isSignupValid)
    }

    func testSignupValidationPasswordLength() {
        viewModel.email = "test@example.com"
        viewModel.password = "short"
        viewModel.confirmPassword = "short"
        viewModel.agreedToTerms = true
        XCTAssertFalse(viewModel.isSignupValid)
    }

    func testSignupValidationPasswordMismatch() {
        viewModel.email = "test@example.com"
        viewModel.password = "Password123"
        viewModel.confirmPassword = "Different123"
        viewModel.agreedToTerms = true
        XCTAssertFalse(viewModel.isSignupValid)
    }

    // MARK: - Child Profile Validation

    func testChildProfileValidation() {
        XCTAssertFalse(viewModel.isChildProfileValid) // Empty nickname

        viewModel.nickname = "TestKid"
        XCTAssertTrue(viewModel.isChildProfileValid)
    }

    func testChildProfileValidationNicknameTooLong() {
        viewModel.nickname = String(repeating: "a", count: 21)
        XCTAssertFalse(viewModel.isChildProfileValid)
    }

    func testChildProfileValidationAgeBounds() {
        viewModel.nickname = "TestKid"

        viewModel.age = 7
        XCTAssertFalse(viewModel.isChildProfileValid)

        viewModel.age = 8
        XCTAssertTrue(viewModel.isChildProfileValid)

        viewModel.age = 18
        XCTAssertTrue(viewModel.isChildProfileValid)

        viewModel.age = 19
        XCTAssertFalse(viewModel.isChildProfileValid)
    }

    // MARK: - PIN Validation

    func testPinValidation() {
        XCTAssertFalse(viewModel.isPinValid)

        viewModel.pin = "1234"
        viewModel.confirmPin = "1234"
        XCTAssertTrue(viewModel.isPinValid)
    }

    func testPinValidationMismatch() {
        viewModel.pin = "1234"
        viewModel.confirmPin = "5678"
        XCTAssertFalse(viewModel.isPinValid)
    }

    func testPinValidationSkip() {
        viewModel.skipPin = true
        XCTAssertTrue(viewModel.isPinValid)
    }

    func testPinValidationNonNumeric() {
        viewModel.pin = "abcd"
        viewModel.confirmPin = "abcd"
        XCTAssertFalse(viewModel.isPinValid)
    }

    // MARK: - Signup Action

    func testSignupSuccess() async {
        viewModel.email = "test@example.com"
        viewModel.password = "Password123"
        viewModel.confirmPassword = "Password123"
        viewModel.agreedToTerms = true

        mockAPI.enqueue(TestFixtures.makeSignupResponse(parentId: "parent-new"))

        await viewModel.signup()

        XCTAssertEqual(viewModel.step, 1) // Advanced to next step
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSignupError() async {
        viewModel.email = "test@example.com"
        viewModel.password = "Password123"
        viewModel.confirmPassword = "Password123"
        viewModel.agreedToTerms = true

        mockAPI.enqueueError(APIError.conflict("Email in use"))

        await viewModel.signup()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.step, 0) // Stayed on same step
    }
}
