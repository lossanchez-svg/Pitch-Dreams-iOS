import Foundation
import SwiftUI

@MainActor
final class ChildLoginViewModel: ObservableObject {
    @Published var parentEmail = ""
    @Published var nickname = ""
    @Published var pin = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    @AppStorage("lastParentEmail") var savedParentEmail = ""

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
        self.parentEmail = savedParentEmail
    }

    var isValid: Bool {
        !parentEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty &&
        pin.count >= 4 && pin.count <= 6 && pin.allSatisfy(\.isNumber)
    }

    func login() async {
        guard isValid else {
            errorMessage = "Please fill in all fields. PIN must be 4-6 digits."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let email = parentEmail.trimmingCharacters(in: .whitespaces).lowercased()
            savedParentEmail = email

            try await authManager.loginChild(
                parentEmail: email,
                nickname: nickname.trimmingCharacters(in: .whitespaces),
                pin: pin
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
