import Foundation

@MainActor
final class WeeklyRecapViewModel: ObservableObject {
    @Published var recap: WeeklyRecap?
    @Published var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol
    private let xpStore: XPStore

    init(childId: String, apiClient: APIClientProtocol = APIClient(), xpStore: XPStore = XPStore()) {
        self.childId = childId
        self.apiClient = apiClient
        self.xpStore = xpStore
    }

    func loadRecap() async {
        isLoading = true
        do {
            let sessions: [SessionLog] = try await apiClient.request(
                APIRouter.listSessions(childId: childId, limit: 50)
            )
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let isoParser = ISO8601DateFormatter()
            let thisWeekDates: [Date] = sessions.compactMap { session in
                guard let date = isoParser.date(from: session.createdAt), date >= weekAgo else { return nil }
                return date
            }
            let thisWeek = sessions.filter { session in
                guard let date = isoParser.date(from: session.createdAt) else { return false }
                return date >= weekAgo
            }

            let totalXP = await xpStore.getTotalXP(childId: childId)

            // Calculate weekly XP from history
            let history = await xpStore.getXPHistory(childId: childId)
            let weeklyXP = history.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.amount }

            // Load profile for avatar
            let profile: ChildProfileDetail? = try? await apiClient.request(
                APIRouter.getProfile(childId: childId)
            )

            // Load streak data
            let streakData: StreakData? = try? await apiClient.request(
                APIRouter.getStreaks(childId: childId)
            )

            recap = WeeklyRecap(
                weekStarting: weekAgo,
                sessionsCompleted: thisWeek.count,
                totalMinutes: thisWeek.compactMap(\.duration).reduce(0, +),
                currentStreak: streakData?.milestones.max() ?? 0,
                xpEarned: weeklyXP,
                totalXP: totalXP,
                avatarId: profile?.avatarId,
                bestDrill: nil,
                personalBests: 0,
                improvementStat: nil,
                weekdayActivity: Self.computeWeekdayActivity(weekStarting: weekAgo, sessionDates: thisWeekDates)
            )
        } catch {
            recap = nil
        }
        isLoading = false
    }

    /// Returns 7 bools, one per day starting at `weekStarting`.
    /// `true` if at least one session was logged that calendar day.
    static func computeWeekdayActivity(weekStarting: Date, sessionDates: [Date]) -> [Bool] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStarting)
        let sessionDays: Set<Date> = Set(sessionDates.map { calendar.startOfDay(for: $0) })
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return false }
            return sessionDays.contains(day)
        }
    }
}
