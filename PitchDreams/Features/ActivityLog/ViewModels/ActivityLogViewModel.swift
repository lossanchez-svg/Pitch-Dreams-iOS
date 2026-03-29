import Foundation

@MainActor
final class ActivityLogViewModel: ObservableObject {
    // MARK: - Form Navigation
    @Published var currentStep: Int = 0

    // MARK: - Step 0: Activity Type
    @Published var activityType: String = ActivityType.selfTraining.rawValue

    // MARK: - Step 1: Details
    @Published var durationMinutes: Int = 30
    @Published var intensityRPE: Int = 5
    @Published var gameIQImpact: String = GameIQImpact.medium.rawValue
    @Published var opponent: String = ""
    @Published var selectedFacilityId: String?
    @Published var selectedCoachId: String?
    @Published var selectedProgramId: String?

    // MARK: - Step 2: Reflection
    @Published var selectedFocusTags: Set<String> = []
    @Published var selectedHighlights: Set<String> = []
    @Published var selectedNextFocus: Set<String> = []
    @Published var notes: String = ""

    // MARK: - Picker Data
    @Published var facilities: [Facility] = []
    @Published var coaches: [Coach] = []
    @Published var programs: [Program] = []
    @Published var focusTags: [FocusTag] = []
    @Published var highlightChips: [HighlightChip] = []
    @Published var nextFocusChips: [NextFocusChip] = []
    @Published var isLoadingPickers = false

    // MARK: - State
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false
    @Published var recentActivities: [ActivityItem] = []
    @Published var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol

    var isGameType: Bool {
        ["OFFICIAL_GAME", "FUTSAL_GAME", "INDOOR_LEAGUE_GAME"].contains(activityType)
    }

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Data Loading

    func loadRecent() async {
        isLoading = true
        errorMessage = nil
        do {
            recentActivities = try await apiClient.request(
                APIRouter.listActivities(childId: childId, limit: 10)
            )
        } catch {
            errorMessage = "Could not load activities."
        }
        isLoading = false
    }

    func loadPickers() async {
        isLoadingPickers = true
        async let f: [Facility] = apiClient.request(APIRouter.listFacilities)
        async let c: [Coach] = apiClient.request(APIRouter.listCoaches)
        async let p: [Program] = apiClient.request(APIRouter.listPrograms)
        async let ft: [FocusTag] = apiClient.request(APIRouter.focusTags)
        async let hl: [HighlightChip] = apiClient.request(APIRouter.highlightTags)
        async let nf: [NextFocusChip] = apiClient.request(APIRouter.nextFocusTags)

        facilities = (try? await f) ?? []
        coaches = (try? await c) ?? []
        programs = (try? await p) ?? []
        focusTags = (try? await ft) ?? []
        highlightChips = (try? await hl) ?? []
        nextFocusChips = (try? await nf) ?? []
        isLoadingPickers = false
    }

    // MARK: - Entity Creation

    func createFacility(name: String, city: String?) async {
        let body = CreateFacilityBody(name: name, city: city, isSaved: true)
        if let created: Facility = try? await apiClient.request(APIRouter.createFacility(body: body)) {
            facilities.append(created)
            selectedFacilityId = created.id
        }
    }

    func createCoach(displayName: String) async {
        let body = CreateCoachBody(displayName: displayName, isSaved: true)
        if let created: Coach = try? await apiClient.request(APIRouter.createCoach(body: body)) {
            coaches.append(created)
            selectedCoachId = created.id
        }
    }

    func createProgram(name: String, type: String) async {
        let body = CreateProgramBody(name: name, type: type, isSaved: true)
        if let created: Program = try? await apiClient.request(APIRouter.createProgram(body: body)) {
            programs.append(created)
            selectedProgramId = created.id
        }
    }

    // MARK: - Navigation

    func nextStep() {
        guard currentStep < 3 else { return }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    // MARK: - Save

    func saveActivity() async {
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        do {
            let body = CreateActivityBody(
                activityType: activityType,
                durationMinutes: durationMinutes,
                gameIQImpact: gameIQImpact,
                focusTagIds: selectedFocusTags.isEmpty ? nil : Array(selectedFocusTags),
                highlightIds: selectedHighlights.isEmpty ? nil : Array(selectedHighlights),
                nextFocusIds: selectedNextFocus.isEmpty ? nil : Array(selectedNextFocus)
            )
            let _: ActivityItem = try await apiClient.request(
                APIRouter.createActivity(childId: childId, body: body)
            )
            saveSuccess = true
            resetForm()
            await loadRecent()
        } catch {
            errorMessage = "Failed to save activity. Please try again."
        }
        isSaving = false
    }

    private func resetForm() {
        currentStep = 0
        activityType = ActivityType.selfTraining.rawValue
        durationMinutes = 30
        intensityRPE = 5
        gameIQImpact = GameIQImpact.medium.rawValue
        opponent = ""
        selectedFacilityId = nil
        selectedCoachId = nil
        selectedProgramId = nil
        selectedFocusTags = []
        selectedHighlights = []
        selectedNextFocus = []
        notes = ""
    }
}
