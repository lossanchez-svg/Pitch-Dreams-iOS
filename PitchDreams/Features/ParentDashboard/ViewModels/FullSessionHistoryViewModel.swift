import Foundation

/// Backing data for `FullSessionHistoryView`. Fetches up to 500 sessions
/// and lets the parent filter across presets (30d / 90d / 180d / 365d / all).
@MainActor
final class FullSessionHistoryViewModel: ObservableObject {
    enum Range: String, CaseIterable, Identifiable {
        case last30   = "30 Days"
        case last90   = "3 Months"
        case last180  = "6 Months"
        case last365  = "1 Year"
        case allTime  = "All Time"
        var id: String { rawValue }

        /// Days of history in the range. `allTime` returns nil — the filter
        /// skips the date comparison entirely.
        var days: Int? {
            switch self {
            case .last30:   return 30
            case .last90:   return 90
            case .last180:  return 180
            case .last365:  return 365
            case .allTime:  return nil
            }
        }
    }

    @Published var range: Range = .last90
    @Published private(set) var allSessions: [SessionLog] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Filtered view

    var filteredSessions: [SessionLog] {
        guard let days = range.days else { return allSessions }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return allSessions.filter {
            guard let d = Self.parseDate($0.createdAt) else { return false }
            return d >= cutoff
        }
    }

    /// Sessions grouped by the first day of the month they occurred in,
    /// newest group first. Drives the sectioned list in the view.
    var groupedByMonth: [(monthStart: Date, sessions: [SessionLog])] {
        let calendar = Calendar.current
        var buckets: [Date: [SessionLog]] = [:]
        for session in filteredSessions {
            guard let d = Self.parseDate(session.createdAt) else { continue }
            let components = calendar.dateComponents([.year, .month], from: d)
            guard let monthStart = calendar.date(from: components) else { continue }
            buckets[monthStart, default: []].append(session)
        }
        return buckets.keys.sorted(by: >).map { monthStart in
            let sorted = (buckets[monthStart] ?? []).sorted {
                (Self.parseDate($0.createdAt) ?? .distantPast) > (Self.parseDate($1.createdAt) ?? .distantPast)
            }
            return (monthStart: monthStart, sessions: sorted)
        }
    }

    var totalSessions: Int { filteredSessions.count }
    var totalMinutes: Int { filteredSessions.compactMap(\.duration).reduce(0, +) }

    var totalHoursFormatted: String {
        let mins = totalMinutes
        guard mins >= 60 else { return "\(mins)m" }
        let h = Double(mins) / 60.0
        return String(format: "%.1fh", h)
    }

    var avgEffort: Double {
        let efforts = filteredSessions.compactMap(\.effortLevel)
        guard !efforts.isEmpty else { return 0 }
        return Double(efforts.reduce(0, +)) / Double(efforts.count)
    }

    var avgEffortLabel: String {
        guard avgEffort > 0 else { return "—" }
        return String(format: "%.1f / 10", avgEffort)
    }

    // MARK: - Load

    /// Fetches the widest reasonable window so the client-side range switcher
    /// is instantaneous. 500 sessions covers several years for most kids.
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            allSessions = try await apiClient.request(
                APIRouter.listSessions(childId: childId, limit: 500)
            )
        } catch {
            allSessions = []
            errorMessage = "Couldn't load training history."
        }
    }

    // MARK: - Helpers

    static func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }
}
