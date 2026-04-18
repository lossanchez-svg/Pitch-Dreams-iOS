import Foundation

/// Tracks daily mystery box state per child. Stores the last-opened
/// timestamp (gates one box per day) and a capped reward history (60
/// entries) used for the box-streak counter on the closed-box card.
actor MysteryBoxStore {
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let historyCap = 60

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    // MARK: - Availability

    /// True when no box has been opened today (or never).
    func isBoxAvailable(childId: String, now: Date = Date()) -> Bool {
        guard let last = lastOpenedDate(childId: childId) else { return true }
        return !calendar.isDate(last, inSameDayAs: now)
    }

    /// Seconds until local midnight — used to display "NEXT BOX IN HH:MM:SS"
    /// on the cooldown state.
    func secondsUntilNextBox(now: Date = Date()) -> TimeInterval {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return max(0, startOfTomorrow.timeIntervalSince(now))
    }

    // MARK: - Opening

    /// Record that today's box was opened with a given reward.
    func recordOpen(reward: MysteryReward, childId: String) {
        defaults.set(reward.openedAt, forKey: lastOpenedKey(childId: childId))
        var history = getHistory(childId: childId)
        history.append(reward)
        if history.count > historyCap {
            history = Array(history.suffix(historyCap))
        }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey(childId: childId))
        }
    }

    // MARK: - History

    func getHistory(childId: String) -> [MysteryReward] {
        guard let data = defaults.data(forKey: historyKey(childId: childId)),
              let entries = try? JSONDecoder().decode([MysteryReward].self, from: data) else {
            return []
        }
        return entries
    }

    /// Number of consecutive days the user has opened a box (capped at 365).
    /// The loop walks backward from today and stops on the first day without
    /// a recorded open.
    func boxStreak(childId: String, now: Date = Date()) -> Int {
        let history = getHistory(childId: childId)
        guard !history.isEmpty else { return 0 }

        let days: Set<Date> = Set(history.map { calendar.startOfDay(for: $0.openedAt) })
        var checkDate = calendar.startOfDay(for: now)
        var streak = 0

        // If today hasn't been opened yet, start the streak check from yesterday.
        if !days.contains(checkDate), let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
            checkDate = yesterday
        }

        for _ in 0..<365 {
            if days.contains(checkDate) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Reset

    func clear(childId: String) {
        defaults.removeObject(forKey: lastOpenedKey(childId: childId))
        defaults.removeObject(forKey: historyKey(childId: childId))
    }

    // MARK: - Private

    private func lastOpenedDate(childId: String) -> Date? {
        defaults.object(forKey: lastOpenedKey(childId: childId)) as? Date
    }

    private func lastOpenedKey(childId: String) -> String { "mbox_last_\(childId)" }
    private func historyKey(childId: String) -> String { "mbox_history_\(childId)" }
}
