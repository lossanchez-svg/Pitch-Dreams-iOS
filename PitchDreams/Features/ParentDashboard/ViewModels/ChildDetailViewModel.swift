import Foundation

@MainActor
final class ChildDetailViewModel: ObservableObject {
    @Published var streakData: StreakData?
    @Published var sessions: [SessionLog] = []
    @Published var activities: [ActivityItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Computed

    var monthlySessionCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { session in
            guard let date = parseDate(session.createdAt) else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }

    var totalMinutesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { session in
            guard let date = parseDate(session.createdAt) else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.compactMap(\.duration).reduce(0, +)
    }

    var currentStreak: Int {
        streakData?.milestones.max() ?? 0
    }

    var avgRPE: Double {
        let efforts = sessions.compactMap(\.effortLevel)
        guard !efforts.isEmpty else { return 0 }
        return Double(efforts.reduce(0, +)) / Double(efforts.count)
    }

    var avgGameIQ: Double {
        let impacts = activities.compactMap { item -> Double? in
            switch item.gameIQImpact {
            case "HIGH": return 3.0
            case "MEDIUM": return 2.0
            case "LOW": return 1.0
            default: return nil
            }
        }
        guard !impacts.isEmpty else { return 0 }
        return impacts.reduce(0, +) / Double(impacts.count)
    }

    var avgGameIQLabel: String {
        let avg = avgGameIQ
        if avg >= 2.5 { return "High" }
        if avg >= 1.5 { return "Medium" }
        if avg > 0 { return "Low" }
        return "N/A"
    }

    var activityBreakdown: [(type: String, count: Int, minutes: Int)] {
        var dict: [String: (count: Int, minutes: Int)] = [:]
        for activity in activities {
            let key = activity.activityType
            let existing = dict[key, default: (count: 0, minutes: 0)]
            dict[key] = (count: existing.count + 1, minutes: existing.minutes + activity.durationMinutes)
        }
        return dict.map { (type: $0.key, count: $0.value.count, minutes: $0.value.minutes) }
            .sorted { $0.count > $1.count }
    }

    var formattedTotalTime: String {
        let mins = totalMinutesThisMonth
        if mins < 60 { return "\(mins)m" }
        let hours = mins / 60
        let remainder = mins % 60
        return remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h"
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
            errorMessage = "Unable to load session data"
        }

        do {
            activities = try await apiClient.request(APIRouter.listActivities(childId: childId, limit: 50))
        } catch {
            activities = []
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }
}
