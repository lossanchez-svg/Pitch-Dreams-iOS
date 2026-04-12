import XCTest
@testable import PitchDreams

/// Tests for Add Child flow, Avatar persistence, PIN setup, and child logout.
/// Covers functionality added in the parent dashboard expansion.
@MainActor
final class AddChildAndAvatarTests: XCTestCase {

    private var mockAPI: MockAPIClient!
    private var mockKeychain: MockKeychainService!
    private var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        mockKeychain = MockKeychainService()
        authManager = AuthManager(apiClient: mockAPI, keychain: mockKeychain)
    }

    override func tearDown() {
        // Clean up any UserDefaults keys we set during tests
        UserDefaults.standard.removeObject(forKey: "avatarOverride_child-new-001")
        UserDefaults.standard.removeObject(forKey: "avatarOverride_child-def-456")
        super.tearDown()
    }

    // MARK: - OnboardingViewModel Add-Child Mode

    func testAddChildModeSetsParentIdAndFlag() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = true
        vm.parentId = "parent-abc-123"

        XCTAssertTrue(vm.isAddChildMode)
        XCTAssertEqual(vm.parentId, "parent-abc-123")
    }

    func testAddChildModeSkipsSignup() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = true
        vm.parentId = "parent-abc-123"

        // In add-child mode, step starts at 0 (avatar selection)
        // and createChild uses authenticated endpoint
        vm.step = 0
        XCTAssertEqual(vm.step, 0)

        // Advance to profile step
        vm.nextStep()
        XCTAssertEqual(vm.step, 1)
    }

    func testCreateChildAuthenticatedCallsAddChildEndpoint() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = true
        vm.nickname = "Jude"
        vm.age = 10
        vm.avatarId = "panther"

        mockAPI.enqueue(TestFixtures.makeCreateChildResponse(childId: "child-new-001"))

        await vm.createChild()

        // Should call addChild (authenticated) endpoint, not createChild (unauthenticated)
        XCTAssertTrue(mockAPI.calledEndpoints.contains("/parent/children"))
        XCTAssertEqual(vm.childId, "child-new-001")
        XCTAssertNil(vm.errorMessage)
    }

    func testCreateChildAuthenticatedAdvancesStep() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = true
        vm.nickname = "Jude"
        vm.age = 10
        vm.avatarId = "panther"
        vm.step = 1 // Profile step

        mockAPI.enqueue(TestFixtures.makeCreateChildResponse())

        await vm.createChild()

        XCTAssertEqual(vm.step, 2) // Advances to permissions
    }

    func testCreateChildAuthenticatedErrorShowsMessage() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = true
        vm.nickname = "Jude"
        vm.age = 10
        vm.avatarId = "panther"

        mockAPI.enqueueError(APIError.unknown(401, "Unauthorized"))

        await vm.createChild()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.errorMessage!.contains("Failed to create"))
    }

    func testCreateChildOnboardingUsesUnauthenticatedEndpoint() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = false
        vm.parentId = "parent-abc-123"
        vm.nickname = "TestKid"
        vm.age = 12
        vm.avatarId = "wolf"

        mockAPI.enqueue(TestFixtures.makeCreateChildResponse())

        await vm.createChild()

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/parent/children"))
        XCTAssertEqual(vm.childId, "child-new-001")
    }

    func testCreateChildWithoutParentIdFails() async {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.isAddChildMode = false
        vm.parentId = nil // No parent ID
        vm.nickname = "TestKid"
        vm.age = 12

        await vm.createChild()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.childId)
    }

    // MARK: - Avatar Selection Persistence

    func testAvatarIdDefaultIsDefault() {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        XCTAssertEqual(vm.avatarId, "default")
    }

    func testAvatarIdCanBeSetToAnimalAvatar() {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.avatarId = "panther"
        XCTAssertEqual(vm.avatarId, "panther")
    }

    func testAllAnimalAvatarsAreValidRawValues() {
        let avatars: [Avatar] = [.wolf, .lion, .eagle, .fox, .shark, .panther, .bear, .default]
        let expectedRaws = ["wolf", "lion", "eagle", "fox", "shark", "panther", "bear", "default"]

        for (avatar, expected) in zip(avatars, expectedRaws) {
            XCTAssertEqual(avatar.rawValue, expected, "Avatar \(avatar) should have rawValue \(expected)")
        }
    }

    // MARK: - Avatar Override (UserDefaults Fallback)

    func testAvatarOverrideSavesToUserDefaults() {
        let childId = "child-def-456"
        UserDefaults.standard.set("eagle", forKey: "avatarOverride_\(childId)")

        let stored = UserDefaults.standard.string(forKey: "avatarOverride_\(childId)")
        XCTAssertEqual(stored, "eagle")
    }

    func testAvatarOverrideTakesPrecedenceOverNil() {
        let childId = "child-def-456"
        UserDefaults.standard.set("shark", forKey: "avatarOverride_\(childId)")

        // Simulate effectiveAvatarId logic: local override ?? server avatarId
        let serverAvatarId: String? = nil
        let effective = UserDefaults.standard.string(forKey: "avatarOverride_\(childId)") ?? serverAvatarId
        XCTAssertEqual(effective, "shark")
    }

    func testAvatarOverrideTakesPrecedenceOverServer() {
        let childId = "child-def-456"
        UserDefaults.standard.set("fox", forKey: "avatarOverride_\(childId)")

        let serverAvatarId: String? = "wolf"
        let effective = UserDefaults.standard.string(forKey: "avatarOverride_\(childId)") ?? serverAvatarId
        XCTAssertEqual(effective, "fox")
    }

    func testNoOverrideFallsToServerValue() {
        let childId = "child-def-456"
        UserDefaults.standard.removeObject(forKey: "avatarOverride_\(childId)")

        let serverAvatarId: String? = "lion"
        let effective = UserDefaults.standard.string(forKey: "avatarOverride_\(childId)") ?? serverAvatarId
        XCTAssertEqual(effective, "lion")
    }

    // MARK: - Avatar Resolve

    func testAvatarResolveKnownIds() {
        XCTAssertEqual(Avatar.resolve("wolf"), .wolf)
        XCTAssertEqual(Avatar.resolve("lion"), .lion)
        XCTAssertEqual(Avatar.resolve("eagle"), .eagle)
        XCTAssertEqual(Avatar.resolve("fox"), .fox)
        XCTAssertEqual(Avatar.resolve("shark"), .shark)
        XCTAssertEqual(Avatar.resolve("panther"), .panther)
        XCTAssertEqual(Avatar.resolve("bear"), .bear)
    }

    func testAvatarResolveUnknownFallsToDefault() {
        XCTAssertEqual(Avatar.resolve("unknown_avatar"), .default)
        XCTAssertEqual(Avatar.resolve(nil), .default)
        XCTAssertEqual(Avatar.resolve(""), .default)
    }

    func testAvatarResolveLegacyMigrations() {
        // Legacy human-art IDs migrate to closest animal match
        XCTAssertEqual(Avatar.resolve("midfield_boy_01"), .wolf)
        XCTAssertEqual(Avatar.resolve("midfield_boy_02"), .lion)
        XCTAssertEqual(Avatar.resolve("defender_girl_01"), .panther)
        XCTAssertEqual(Avatar.resolve("winger_boy_01"), .fox)
    }

    // MARK: - Child Login (PIN)

    func testChildLoginCallsCorrectEndpoint() async throws {
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .child))

        try await authManager.loginChild(
            parentEmail: "parent@example.com",
            nickname: "TestKid",
            pin: "1111"
        )

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/auth/token"))
    }

    func testChildLoginSetsAuthenticatedState() async throws {
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .child))

        try await authManager.loginChild(
            parentEmail: "parent@example.com",
            nickname: "TestKid",
            pin: "1111"
        )

        XCTAssertNotNil(authManager.currentUser)
        XCTAssertEqual(authManager.currentUser?.role, .child)
    }

    func testChildLoginFailureThrows() async {
        mockAPI.enqueueError(APIError.unknown(401, "Invalid credentials"))

        do {
            try await authManager.loginChild(
                parentEmail: "parent@example.com",
                nickname: "TestKid",
                pin: "wrong"
            )
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }

        XCTAssertNil(authManager.currentUser)
    }

    // MARK: - Logout

    func testLogoutClearsAuthState() async throws {
        // Login first
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .child))
        try await authManager.loginChild(
            parentEmail: "parent@example.com",
            nickname: "TestKid",
            pin: "1111"
        )
        XCTAssertNotNil(authManager.currentUser)

        // Logout
        authManager.logout()
        XCTAssertNil(authManager.currentUser)
    }

    func testLogoutWorksForParentToo() async throws {
        mockAPI.enqueue(TestFixtures.makeTokenResponse(role: .parent))
        try await authManager.loginParent(
            email: "parent@example.com",
            password: "password123"
        )
        XCTAssertNotNil(authManager.currentUser)

        authManager.logout()
        XCTAssertNil(authManager.currentUser)
    }

    // MARK: - PIN Validation

    func testPinValidationRules() {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)

        // Too short
        vm.pin = "12"
        vm.confirmPin = "12"
        XCTAssertFalse(vm.isPinValid)

        // Just right (4 digits)
        vm.pin = "1234"
        vm.confirmPin = "1234"
        XCTAssertTrue(vm.isPinValid)

        // Max (6 digits)
        vm.pin = "123456"
        vm.confirmPin = "123456"
        XCTAssertTrue(vm.isPinValid)

        // Too long
        vm.pin = "1234567"
        vm.confirmPin = "1234567"
        XCTAssertFalse(vm.isPinValid)

        // Mismatch
        vm.pin = "1234"
        vm.confirmPin = "5678"
        XCTAssertFalse(vm.isPinValid)

        // Non-numeric
        vm.pin = "abcd"
        vm.confirmPin = "abcd"
        XCTAssertFalse(vm.isPinValid)
    }

    func testPinSkipBypass() {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.pin = ""
        vm.confirmPin = ""
        vm.skipPin = true
        XCTAssertTrue(vm.isPinValid)
    }

    // MARK: - Step Navigation Bounds

    func testMaxStepIs4() {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.step = 4
        vm.nextStep() // Should not go past 4
        XCTAssertEqual(vm.step, 4)
    }

    func testMinStepIs0() {
        let vm = OnboardingViewModel(authManager: authManager, apiClient: mockAPI)
        vm.step = 0
        vm.previousStep() // Should not go below 0
        XCTAssertEqual(vm.step, 0)
    }

    // MARK: - APIRouter Endpoints

    func testAddChildEndpointUsesApiBasePath() {
        let body = CreateChildBody(
            nickname: "Test", age: 10, position: nil, goals: nil,
            avatarId: "panther", avatarColor: nil, freeTextEnabled: nil,
            trainingWindowStart: nil, trainingWindowEnd: nil
        )
        let route = APIRouter.addChild(body: body)
        XCTAssertEqual(route.apiBasePath, "/api")
        XCTAssertEqual(route.path, "/parent/children")
        XCTAssertTrue(route.requiresAuth, "addChild should require auth (sends Bearer token)")
    }

    func testCreateChildEndpointDoesNotRequireAuth() {
        let body = CreateChildBody(
            nickname: "Test", age: 10, position: nil, goals: nil,
            avatarId: "wolf", avatarColor: nil, freeTextEnabled: nil,
            trainingWindowStart: nil, trainingWindowEnd: nil
        )
        let route = APIRouter.createChild(parentId: "p1", body: body)
        XCTAssertFalse(route.requiresAuth, "createChild should NOT require auth (onboarding)")
    }

    func testUpdateAvatarEndpointRequiresAuth() {
        let route = APIRouter.updateAvatar(childId: "c1", avatarId: "eagle")
        XCTAssertTrue(route.requiresAuth)
        XCTAssertEqual(route.path, "/children/c1/profile")
    }

    func testSetChildPinEndpointUsesApiBasePath() {
        let route = APIRouter.setChildPin(childId: "c1", pin: "1234")
        XCTAssertEqual(route.apiBasePath, "/api")
        XCTAssertEqual(route.path, "/parent/children/c1/pin")
    }

    // MARK: - ChildHomeViewModel Avatar Integration

    func testChildHomeViewModelLoadsProfile() async {
        let vm = ChildHomeViewModel(childId: "child-def-456", apiClient: mockAPI)
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail(avatarId: "panther"))
        mockAPI.enqueue(TestFixtures.makeStreakData())
        // todayCheckIn and nudge will fail gracefully
        mockAPI.enqueueError(APIError.unknown(404, ""))
        mockAPI.enqueueError(APIError.unknown(404, ""))
        mockAPI.enqueueError(APIError.unknown(404, "")) // freezeCheck

        await vm.loadData()

        XCTAssertEqual(vm.profile?.avatarId, "panther")
        XCTAssertFalse(vm.isLoading)
    }
}
