import XCTest
@testable import PitchDreams

@MainActor
final class ForgotPasswordViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: ForgotPasswordViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = ForgotPasswordViewModel(apiClient: mockAPI)
    }

    func testSendResetLinkSuccess() async {
        viewModel.email = "test@example.com"

        await viewModel.sendResetLink()

        XCTAssertTrue(viewModel.emailSent)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSendResetLinkError() async {
        viewModel.email = "test@example.com"
        mockAPI.enqueueError(APIError.server("Server error"))

        await viewModel.sendResetLink()

        XCTAssertFalse(viewModel.emailSent)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSendResetLinkInvalidEmail() async {
        viewModel.email = "notanemail"

        await viewModel.sendResetLink()

        XCTAssertFalse(viewModel.emailSent)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testSendResetLinkEmptyEmail() async {
        viewModel.email = ""

        await viewModel.sendResetLink()

        XCTAssertFalse(viewModel.emailSent)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testIsValidCheck() {
        viewModel.email = ""
        XCTAssertFalse(viewModel.isValid)

        viewModel.email = "test@example.com"
        XCTAssertTrue(viewModel.isValid)

        viewModel.email = "invalid"
        XCTAssertFalse(viewModel.isValid)
    }

    func testCallsCorrectEndpoint() async {
        viewModel.email = "test@example.com"

        await viewModel.sendResetLink()

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/auth/forgot-password"))
    }
}
