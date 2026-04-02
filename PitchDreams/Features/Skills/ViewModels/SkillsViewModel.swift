import Foundation

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published var drillStats: [DrillStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    func loadStats() async {
        isLoading = true
        errorMessage = nil
        do {
            drillStats = try await apiClient.request(
                APIRouter.drillStats(childId: childId)
            )
        } catch {
            errorMessage = "Could not load drill stats."
        }
        isLoading = false
    }

    func logDrill(drillKey: String, confidence: Int) async {
        errorMessage = nil
        do {
            let body = LogDrillBody(drillKey: drillKey, repsCount: 1, confidence: confidence)
            let _: LogDrillResult = try await apiClient.request(
                APIRouter.logDrill(childId: childId, body: body)
            )
            await loadStats()
        } catch {
            errorMessage = "Failed to log drill: \(error.localizedDescription)"
        }
    }
}
