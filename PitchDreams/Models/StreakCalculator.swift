import Foundation

/// Day-walk streak math over session logs, shared by Progress and Confidence
/// so "streak" always means the same thing everywhere the kid sees it.
/// The server's `StreakData` carries freezes and milestone badges but not the
/// live streak — that is always derived from the session history.
enum StreakCalculator {
    /// Contiguous run of training days ending today or yesterday, walking
    /// back from `now`. Today gets a grace pass (the kid may just not have
    /// trained *yet*), but a run that ended before yesterday is over — it
    /// counts toward `maxStreak`, not the live streak.
    static func currentStreak(
        from sessions: [SessionLog],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let dates = sessionDays(from: sessions, calendar: calendar)
        var streak = 0
        var checkDate = now
        for dayOffset in 0..<365 {
            let components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if dates.contains(components) {
                streak += 1
            } else if dayOffset > 0 {
                break
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    /// Longest contiguous run of training days in the past year.
    static func maxStreak(
        from sessions: [SessionLog],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let dates = sessionDays(from: sessions, calendar: calendar)
        var best = 0
        var current = 0
        var checkDate = now
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

    static func sessionDays(
        from sessions: [SessionLog],
        calendar: Calendar = .current
    ) -> Set<DateComponents> {
        Set(
            sessions.compactMap { session in
                guard let date = parseDate(session.createdAt) else { return nil }
                return calendar.dateComponents([.year, .month, .day], from: date)
            }
        )
    }

    static func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }
}
