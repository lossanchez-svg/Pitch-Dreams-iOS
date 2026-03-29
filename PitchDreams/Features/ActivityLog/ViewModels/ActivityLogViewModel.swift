import Foundation

@MainActor
final class ActivityLogViewModel: ObservableObject {
    @Published var activityType: String = ActivityType.selfTraining.rawValue
    @Published var durationMinutes: Int = 30
    @Published var intensityRPE: Int = 5
    @Published var gameIQImpact: String = GameIQImpact.medium.rawValue
    @Published var notes: String = ""
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false
    @Published var recentActivities: [ActivityItem] = []
    @Published var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

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

    func saveActivity() async {
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        do {
            let body = CreateActivityBody(
                activityType: activityType,
                durationMinutes: durationMinutes,
                gameIQImpact: gameIQImpact,
                focusTagIds: nil,
                highlightIds: nil,
                nextFocusIds: nil
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
        activityType = ActivityType.selfTraining.rawValue
        durationMinutes = 30
        intensityRPE = 5
        gameIQImpact = GameIQImpact.medium.rawValue
        notes = ""
    }
}
