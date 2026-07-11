import Foundation

/// Local persistence for Match Mode, following the `PersonalBestStore`
/// pattern. Tracks the latest prep (so the kid can re-read their goal at
/// halftime) and the courage flywheel: how many matches banked a brave play.
actor MatchStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Prep

    func savePrep(_ prep: MatchPrep, childId: String) {
        if let data = try? JSONEncoder().encode(prep) {
            defaults.set(data, forKey: key("latest_prep", childId))
        }
    }

    func latestPrep(childId: String) -> MatchPrep? {
        guard let data = defaults.data(forKey: key("latest_prep", childId)) else { return nil }
        return try? JSONDecoder().decode(MatchPrep.self, from: data)
    }

    // MARK: - Reflection / courage flywheel

    func recordReflection(_ reflection: MatchReflection, childId: String) {
        defaults.set(matchesReflected(childId: childId) + 1, forKey: key("matches_reflected", childId))
        if reflection.braveThingTried != nil {
            defaults.set(bravePlays(childId: childId) + 1, forKey: key("brave_plays", childId))
        }
    }

    /// Matches where the kid banked something brave they tried.
    func bravePlays(childId: String) -> Int {
        defaults.integer(forKey: key("brave_plays", childId))
    }

    func matchesReflected(childId: String) -> Int {
        defaults.integer(forKey: key("matches_reflected", childId))
    }

    private func key(_ field: String, _ childId: String) -> String {
        "match_\(field)_\(childId)"
    }
}
