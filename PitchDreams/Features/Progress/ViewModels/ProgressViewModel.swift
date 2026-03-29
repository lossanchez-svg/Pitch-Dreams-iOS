import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var streakData: StreakData?
    @Published var sessions: [SessionLog] = []
    @Published var trends: [WeeklyTrend]?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Computed

    var totalSessions: Int {
        sessions.count
    }

    var totalMinutes: Int {
        sessions.compactMap(\.duration).reduce(0, +)
    }

    var averageEffort: Double {
        let efforts = sessions.compactMap(\.effortLevel)
        guard !efforts.isEmpty else { return 0 }
        return Double(efforts.reduce(0, +)) / Double(efforts.count)
    }

    var currentStreak: Int {
        // Approximate streak from consecutive days with sessions
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()

        let dates: Set<DateComponents> = Set(
            sessions.compactMap { session in
                guard let date = isoFormatter.date(from: session.createdAt)
                        ?? fallback.date(from: session.createdAt) else { return nil }
                return calendar.dateComponents([.year, .month, .day], from: date)
            }
        )

        var streak = 0
        var checkDate = Date()
        for _ in 0..<365 {
            let components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if dates.contains(components) {
                streak += 1
            } else if streak > 0 {
                break
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    var recentSessions: [SessionLog] {
        Array(sessions.prefix(10))
    }

    var freezesAvailable: Int {
        streakData?.freezes ?? 0
    }

    var milestonesAchieved: [Int] {
        streakData?.milestones ?? []
    }

    // MARK: - Load

    func loadData() async {
        isLoading = true
        errorMessage = nil

        async let streakTask: StreakData? = try? apiClient.request(
            APIRouter.getStreaks(childId: childId)
        )
        async let sessionsTask: [SessionLog] = (try? apiClient.request(
            APIRouter.listSessions(childId: childId, limit: 50)
        )) ?? []
        async let trendsTask: [WeeklyTrend]? = try? apiClient.request(
            APIRouter.getTrends(childId: childId, weeks: 4)
        )

        let (s, sess, t) = await (streakTask, sessionsTask, trendsTask)
        streakData = s
        sessions = sess
        trends = t
        isLoading = false
    }
}
