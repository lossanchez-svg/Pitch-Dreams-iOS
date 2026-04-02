import Foundation

@MainActor
final class QuickLogViewModel: ObservableObject {
    @Published var selectedType: String = "solo"
    @Published var duration: Int = 30
    @Published var effort: Int = 3
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Types

    static let sessionTypes: [(key: String, label: String, icon: String)] = [
        ("solo", "Solo Training", "figure.run"),
        ("team", "Team Practice", "person.3.fill"),
        ("game", "Game", "soccerball"),
        ("class", "Facility Class", "building.2.fill"),
    ]

    var typeDisplayName: String {
        Self.sessionTypes.first(where: { $0.key == selectedType })?.label ?? selectedType.capitalized
    }

    static let effortLabels: [(value: Int, emoji: String, label: String)] = [
        (1, "😌", "Easy"),
        (2, "🙂", "Light"),
        (3, "💪", "Moderate"),
        (4, "🔥", "Hard"),
        (5, "😤", "All Out"),
    ]

    // MARK: - Save

    func save() async {
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        do {
            let body = QuickSessionBody(
                type: selectedType,
                duration: duration,
                effort: effort
            )
            let _: SessionSaveResult = try await apiClient.request(
                APIRouter.createQuickSession(childId: childId, body: body)
            )
            saveSuccess = true
            resetForm()
        } catch {
            errorMessage = "Failed to log session: \(error.localizedDescription)"
        }
        isSaving = false
    }

    private func resetForm() {
        selectedType = "solo"
        duration = 30
        effort = 3
    }
}
