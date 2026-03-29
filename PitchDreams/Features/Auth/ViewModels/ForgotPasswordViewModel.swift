import Foundation

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var emailSent = false

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    var isValid: Bool {
        !email.isEmpty && email.contains("@") && email.contains(".")
    }

    func sendResetLink() async {
        guard isValid else {
            errorMessage = "Please enter a valid email address."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await apiClient.requestVoid(APIRouter.forgotPassword(email: email))
            emailSent = true
        } catch {
            errorMessage = "Could not send reset link. Please check your email and try again."
        }
        isLoading = false
    }
}
