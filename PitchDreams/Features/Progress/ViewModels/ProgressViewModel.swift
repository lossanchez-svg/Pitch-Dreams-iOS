import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var streakData: StreakData?
    @Published var sessions: [SessionLog] = []
    @Published var trends: [WeeklyTrend]?
    @Published var profile: ChildProfileDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient.shared) {
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
        StreakCalculator.currentStreak(from: sessions)
    }

    var maxStreak: Int {
        StreakCalculator.maxStreak(from: sessions)
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
        Array(sessions.prefix(5))
    }

    /// True when the kid's current run is also their best-ever run — a real
    /// "you beat your record" moment, drawn straight from existing streak data.
    var isOnBestEverStreak: Bool {
        currentStreak >= 2 && currentStreak >= maxStreak
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

        do {
            streakData = try await apiClient.request(APIRouter.getStreaks(childId: childId))
        } catch {
            streakData = nil
        }

        do {
            sessions = try await apiClient.request(APIRouter.listSessions(childId: childId, limit: 100))
        } catch {
            sessions = []
            errorMessage = "Unable to load sessions"
        }

        do {
            trends = try await apiClient.request(APIRouter.getTrends(childId: childId, weeks: 4))
        } catch {
            trends = nil
        }

        // Profile is best-effort and fetched last so tests that mock the
        // other three endpoints in order aren't disturbed. Empty state
        // uses this to render the avatar-based illustration when the
        // kid hasn't trained yet.
        profile = try? await apiClient.request(APIRouter.getProfile(childId: childId))

        isLoading = false
    }

    // MARK: - Helpers

    private func parseDate(_ isoString: String) -> Date? {
        StreakCalculator.parseDate(isoString)
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
