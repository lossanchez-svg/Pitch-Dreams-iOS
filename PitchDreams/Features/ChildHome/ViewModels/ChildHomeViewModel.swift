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

        // Load each independently — don't let one failure block others
        do {
            profile = try await apiClient.request(APIRouter.getProfile(childId: childId))
        } catch {
            Log.api.error("Profile load failed: \(error)")
        }

        do {
            streakData = try await apiClient.request(APIRouter.getStreaks(childId: childId))
        } catch {
            Log.api.error("Streak load failed: \(error)")
        }

        // todayCheckIn returns null when no check-in exists — that's normal
        do {
            todayCheckIn = try await apiClient.request(APIRouter.todayCheckIn(childId: childId))
        } catch {
            todayCheckIn = nil // No check-in today is normal
        }

        // Nudge returns null when engagement is good — that's normal
        do {
            nudge = try await apiClient.request(APIRouter.getNudge(childId: childId))
        } catch {
            nudge = nil
        }

        isLoading = false

        // Auto-check streak freeze (fire and forget)
        do {
            let _: FreezeCheckResult = try await apiClient.request(APIRouter.checkFreeze(childId: childId))
        } catch {
            // Not critical
        }
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
