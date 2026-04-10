import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Navigation
    @Published var step: Int = 0

    // MARK: - Step 0: Signup
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var agreedToTerms = false

    // MARK: - Step 1: Child Profile
    @Published var nickname = ""
    @Published var age: Int = 10
    @Published var position = "Just playing for fun"
    @Published var selectedGoals: Set<String> = []
    @Published var avatarId = "default"
    @Published var avatarColor: String? = nil

    // MARK: - Step 2: Permissions
    @Published var freeTextEnabled = false
    @Published var trainingWindowEnabled = false
    @Published var windowStart = ""
    @Published var windowEnd = ""

    // MARK: - Step 3: PIN
    @Published var pin = ""
    @Published var confirmPin = ""
    @Published var skipPin = false

    // MARK: - State
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Created IDs
    private(set) var parentId: String?
    private(set) var childId: String?

    private let apiClient: APIClientProtocol
    private let authManager: AuthManager

    init(authManager: AuthManager, apiClient: APIClientProtocol = APIClient()) {
        self.authManager = authManager
        self.apiClient = apiClient
    }

    // MARK: - Validation

    var isSignupValid: Bool {
        !email.isEmpty && email.contains("@") && email.contains(".") &&
        password.count >= 8 && password == confirmPassword && agreedToTerms
    }

    var isChildProfileValid: Bool {
        !nickname.isEmpty && nickname.count <= 20 && age >= 8 && age <= 18
    }

    var isPinValid: Bool {
        skipPin || (pin.count >= 4 && pin.count <= 6 && pin == confirmPin && pin.allSatisfy(\.isNumber))
    }

    // MARK: - Navigation

    func nextStep() {
        guard step < 4 else { return }
        step += 1
    }

    func previousStep() {
        guard step > 0 else { return }
        step -= 1
    }

    // MARK: - Actions

    func signup() async {
        guard isSignupValid else {
            errorMessage = "Please check all fields are filled correctly."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let response: SignupResponse = try await apiClient.request(
                APIRouter.signup(email: email, password: password)
            )
            parentId = response.parentId
            nextStep()
        } catch {
            errorMessage = "Signup failed. This email may already be in use."
        }
        isLoading = false
    }

    func createChild() async {
        guard isChildProfileValid, let pid = parentId else {
            errorMessage = "Please complete the child profile."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let body = CreateChildBody(
                nickname: nickname,
                age: age,
                position: position == "Just playing for fun" ? nil : position,
                goals: selectedGoals.isEmpty ? nil : Array(selectedGoals),
                avatarId: avatarId,
                avatarColor: avatarColor,
                freeTextEnabled: freeTextEnabled,
                trainingWindowStart: trainingWindowEnabled && !windowStart.isEmpty ? windowStart : nil,
                trainingWindowEnd: trainingWindowEnabled && !windowEnd.isEmpty ? windowEnd : nil,
                parentId: pid
            )
            _ = body // suppress unused warning
            let response: CreateChildResponse = try await apiClient.request(
                APIRouter.createChild(parentId: pid, body: body)
            )
            childId = response.childId
            nextStep()
        } catch {
            errorMessage = "Failed to create child profile: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func completePermissionsStep() {
        nextStep()
    }

    func setPin() async {
        guard let cid = childId else { return }
        if skipPin {
            await finishOnboarding()
            return
        }
        guard isPinValid else {
            errorMessage = "PIN must be 4-6 digits and both entries must match."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await apiClient.requestVoid(APIRouter.setChildPin(childId: cid, pin: pin))
            await finishOnboarding()
        } catch {
            errorMessage = "Failed to set PIN: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func finishOnboarding() async {
        do {
            try await authManager.loginParent(email: email, password: password)
        } catch {
            errorMessage = "Account created but login failed. Please log in manually."
            isLoading = false
        }
    }
}
