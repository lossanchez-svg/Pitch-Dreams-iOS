import Foundation

/// Aggregates a child's session log into trend buckets for `AdvancedAnalyticsView`.
/// Reuses `ChildDetailViewModel.sessions` as the data source — the 100-session
/// default from `listSessions` comfortably covers 12 weeks for most kids.
@MainActor
final class AdvancedAnalyticsViewModel: ObservableObject {
    @Published private(set) var weeklyBuckets: [WeeklyBucket] = []
    @Published private(set) var monthlyBuckets: [MonthlyBucket] = []
    @Published private(set) var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Derived stats shown above the charts

    var totalSessions: Int { weeklyBuckets.map(\.sessionCount).reduce(0, +) }
    var totalMinutes: Int { weeklyBuckets.map(\.minutes).reduce(0, +) }

    var avgSessionsPerWeek: Double {
        guard !weeklyBuckets.isEmpty else { return 0 }
        return Double(totalSessions) / Double(weeklyBuckets.count)
    }

    var avgMinutesPerSession: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(totalMinutes) / Double(totalSessions)
    }

    /// Simple month-over-month delta on session count. Positive = improving.
    var monthOverMonthPercent: Int? {
        guard monthlyBuckets.count >= 2 else { return nil }
        let thisMonth = monthlyBuckets.last!.sessionCount
        let lastMonth = monthlyBuckets[monthlyBuckets.count - 2].sessionCount
        guard lastMonth > 0 else { return nil }
        let delta = Double(thisMonth - lastMonth) / Double(lastMonth) * 100
        return Int(delta.rounded())
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let sessions: [SessionLog] = try await apiClient.request(
                APIRouter.listSessions(childId: childId, limit: 200)
            )
            rebuild(from: sessions)
        } catch {
            weeklyBuckets = []
            monthlyBuckets = []
        }
    }

    // MARK: - Aggregation

    /// Bucket sessions into the trailing 12 ISO weeks (ending this week) and
    /// trailing 6 calendar months (ending this month). Empty weeks/months
    /// still appear so the charts render smoothly without gaps.
    private func rebuild(from sessions: [SessionLog]) {
        let calendar = Calendar.current
        let now = Date()

        // Weekly: last 12 weeks ending this week
        var weeks: [WeeklyBucket] = []
        for weeksAgo in (0..<12).reversed() {
            let anchor = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now) ?? now
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)
            guard let weekStart = calendar.date(from: components) else { continue }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

            let weekSessions = sessions.filter {
                guard let d = Self.parseDate($0.createdAt) else { return false }
                return d >= weekStart && d < weekEnd
            }
            weeks.append(WeeklyBucket(
                weekStart: weekStart,
                sessionCount: weekSessions.count,
                minutes: weekSessions.compactMap(\.duration).reduce(0, +),
                avgEffort: averageEffort(weekSessions)
            ))
        }
        weeklyBuckets = weeks

        // Monthly: last 6 months ending this month
        var months: [MonthlyBucket] = []
        for monthsAgo in (0..<6).reversed() {
            let anchor = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let components = calendar.dateComponents([.year, .month], from: anchor)
            guard let monthStart = calendar.date(from: components) else { continue }
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

            let monthSessions = sessions.filter {
                guard let d = Self.parseDate($0.createdAt) else { return false }
                return d >= monthStart && d < monthEnd
            }
            months.append(MonthlyBucket(
                monthStart: monthStart,
                sessionCount: monthSessions.count,
                minutes: monthSessions.compactMap(\.duration).reduce(0, +)
            ))
        }
        monthlyBuckets = months
    }

    private func averageEffort(_ sessions: [SessionLog]) -> Double? {
        let efforts = sessions.compactMap(\.effortLevel)
        guard !efforts.isEmpty else { return nil }
        return Double(efforts.reduce(0, +)) / Double(efforts.count)
    }

    private static func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }
}

struct WeeklyBucket: Identifiable, Equatable {
    var id: Date { weekStart }
    let weekStart: Date
    let sessionCount: Int
    let minutes: Int
    /// nil when the week had no sessions (so the trend line breaks cleanly
    /// instead of dropping to zero and faking a "bad week").
    let avgEffort: Double?
}

struct MonthlyBucket: Identifiable, Equatable {
    var id: Date { monthStart }
    let monthStart: Date
    let sessionCount: Int
    let minutes: Int
}
