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

    var formattedTotalTime: String {
        let mins = totalMinutes
        if mins < 60 { return "\(mins)m" }
        let hours = mins / 60
        let remainder = mins % 60
        return remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h"
    }

    var averageEffort: Double {
        let efforts = sessions.compactMap(\.effortLevel)
        guard !efforts.isEmpty else { return 0 }
        return Double(efforts.reduce(0, +)) / Double(efforts.count)
    }

    var currentStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        let dates = sessionDates
        var streak = 0
        let calendar = Calendar.current
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

    var maxStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        let dates = sessionDates
        let calendar = Calendar.current
        var best = 0
        var current = 0
        // Go back up to 365 days
        var checkDate = Date()
        for _ in 0..<365 {
            let components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if dates.contains(components) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return best
    }

    var thisMonthSessions: Int {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { session in
            guard let date = parseDate(session.createdAt) else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
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
            APIRouter.listSessions(childId: childId, limit: 100)
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

    // MARK: - Helpers

    private var sessionDates: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(
            sessions.compactMap { session in
                guard let date = parseDate(session.createdAt) else { return nil }
                return calendar.dateComponents([.year, .month, .day], from: date)
            }
        )
    }

    private func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }

    /// Parse a JSON array string or comma-separated string into chips
    func parseChips(_ value: String?) -> [String] {
        guard let value, !value.isEmpty else { return [] }
        // Try JSON array first
        if value.hasPrefix("["),
           let data = value.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array
        }
        // Fall back to comma-separated
        return value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
