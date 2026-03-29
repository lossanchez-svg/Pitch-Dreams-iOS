import Foundation

@MainActor
final class ChildHomeViewModel: ObservableObject {
    @Published var profile: ChildProfileDetail?
    @Published var streakData: StreakData?
    @Published var todayCheckIn: CheckIn?
    @Published var nudge: CoachNudge?
    @Published var isLoading = true
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    var streakCount: Int {
        // Streak is calculated server-side; for now show milestones as proxy
        streakData?.milestones.max() ?? 0
    }

    var freezeCount: Int {
        streakData?.freezes ?? 0
    }

    var hasCheckedInToday: Bool {
        todayCheckIn != nil
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        async let profileTask: ChildProfileDetail? = try? apiClient.request(APIRouter.getProfile(childId: childId))
        async let streakTask: StreakData? = try? apiClient.request(APIRouter.getStreaks(childId: childId))
        async let checkInTask: CheckIn? = try? apiClient.request(APIRouter.todayCheckIn(childId: childId))
        async let nudgeTask: CoachNudge? = try? apiClient.request(APIRouter.getNudge(childId: childId))

        let (p, s, c, n) = await (profileTask, streakTask, checkInTask, nudgeTask)
        profile = p
        streakData = s
        todayCheckIn = c
        nudge = n
        isLoading = false

        // Auto-check streak freeze
        let _: FreezeCheckResult? = try? await apiClient.request(APIRouter.checkFreeze(childId: childId))
    }
}

// MARK: - Coach Nudge model

struct CoachNudge: Codable {
    let type: String
    let title: String
    let message: String
    let actionLabel: String
    let actionValue: String?
}
