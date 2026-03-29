import Foundation

@MainActor
final class ParentLoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    var isValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 8
    }

    func login() async {
        guard isValid else {
            errorMessage = "Please enter a valid email and password (8+ characters)"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.loginParent(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
