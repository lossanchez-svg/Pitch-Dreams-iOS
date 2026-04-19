import Foundation

/// Backing data for the Development Profile PDF. Aggregates a child's
/// sessions + activities + streak data for a parent-chosen period.
///
/// Periods:
/// - `thisMonth`: sessions since the 1st of the current calendar month
/// - `last3Months`: trailing 90 days
/// - `thisSeason`: trailing 6 months (proxy for a soccer season)
@MainActor
final class DevelopmentProfileViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisSeason = "This Season"

        var id: String { rawValue }

        /// Days of history the report covers. Used for date-range filtering
        /// and also rendered in the PDF header.
        var days: Int {
            switch self {
            case .thisMonth:    return 31
            case .last3Months:  return 90
            case .thisSeason:   return 180
            }
        }
    }

    @Published var period: Period = .last3Months
    @Published var parentNote: String = ""
    @Published private(set) var sessions: [SessionLog] = []
    @Published private(set) var activities: [ActivityItem] = []
    @Published private(set) var streakData: StreakData?
    @Published private(set) var profile: ChildProfileDetail?
    @Published private(set) var isLoading = false

    let child: ChildSummary
    var childId: String { child.id }
    var childName: String { child.nickname }
    private let apiClient: APIClientProtocol

    init(child: ChildSummary, apiClient: APIClientProtocol = APIClient()) {
        self.child = child
        self.apiClient = apiClient
    }

    // MARK: - Derived stats scoped to the chosen period

    private var periodStart: Date {
        let calendar = Calendar.current
        if period == .thisMonth {
            let components = calendar.dateComponents([.year, .month], from: Date())
            return calendar.date(from: components) ?? Date()
        }
        return calendar.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()
    }

    private var scopedSessions: [SessionLog] {
        sessions.filter {
            guard let d = Self.parseDate($0.createdAt) else { return false }
            return d >= periodStart
        }
    }

    private var scopedActivities: [ActivityItem] {
        activities.filter {
            guard let d = Self.parseDate($0.createdAt) else { return false }
            return d >= periodStart
        }
    }

    var periodLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: periodStart)) – \(formatter.string(from: Date()))"
    }

    var totalSessions: Int { scopedSessions.count }

    var totalMinutes: Int { scopedSessions.compactMap(\.duration).reduce(0, +) }

    var totalHoursFormatted: String {
        let mins = totalMinutes
        guard mins >= 60 else { return "\(mins)m" }
        let h = Double(mins) / 60.0
        return String(format: "%.1fh", h)
    }

    var currentStreak: Int { streakData?.milestones.max() ?? 0 }

    var avgEffort: Double {
        let efforts = scopedSessions.compactMap(\.effortLevel)
        guard !efforts.isEmpty else { return 0 }
        return Double(efforts.reduce(0, +)) / Double(efforts.count)
    }

    var avgEffortLabel: String {
        guard avgEffort > 0 else { return "—" }
        return String(format: "%.1f / 10", avgEffort)
    }

    /// Activity breakdown for the PDF bar chart — sorted by count descending
    /// so the most-practiced activity leads.
    var activityBreakdown: [(type: String, count: Int, minutes: Int)] {
        var dict: [String: (count: Int, minutes: Int)] = [:]
        for activity in scopedActivities {
            let key = activity.activityType
            let existing = dict[key, default: (count: 0, minutes: 0)]
            dict[key] = (count: existing.count + 1, minutes: existing.minutes + activity.durationMinutes)
        }
        return dict.map { (type: $0.key, count: $0.value.count, minutes: $0.value.minutes) }
            .sorted { $0.count > $1.count }
    }

    /// Four-week trailing sessions-per-week for the trend sparkline.
    var sessionsLast4Weeks: [Int] {
        let calendar = Calendar.current
        return (0..<4).reversed().map { weeksAgo -> Int in
            let anchor = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()) ?? Date()
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)
            guard let weekStart = calendar.date(from: components) else { return 0 }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            return sessions.filter {
                guard let d = Self.parseDate($0.createdAt) else { return false }
                return d >= weekStart && d < weekEnd
            }.count
        }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let profileResult: ChildProfileDetail? = try? apiClient.request(APIRouter.getProfile(childId: childId))
        async let streakResult: StreakData? = try? apiClient.request(APIRouter.getStreaks(childId: childId))
        async let sessionsResult: [SessionLog]? = try? apiClient.request(APIRouter.listSessions(childId: childId, limit: 200))
        async let activitiesResult: [ActivityItem]? = try? apiClient.request(APIRouter.listActivities(childId: childId, limit: 200))

        let (p, s, ss, aa) = await (profileResult, streakResult, sessionsResult, activitiesResult)
        profile = p
        streakData = s
        sessions = ss ?? []
        activities = aa ?? []
    }

    // MARK: - Helpers

    private static func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }
}
