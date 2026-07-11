import Foundation

/// Local record of Creativity Lab progress, following `PersonalBestStore`.
/// Tracks completions per challenge and the kid's invented move names.
actor CreativityStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordCompletion(challengeId: String, childId: String) {
        let k = key("done_\(challengeId)", childId)
        defaults.set(defaults.integer(forKey: k) + 1, forKey: k)
    }

    func completions(challengeId: String, childId: String) -> Int {
        defaults.integer(forKey: key("done_\(challengeId)", childId))
    }

    func totalCompletions(childId: String) -> Int {
        CreativityChallengeRegistry.all
            .map { completions(challengeId: $0.id, childId: childId) }
            .reduce(0, +)
    }

    // MARK: - Invented moves

    func saveInventedMove(_ name: String, childId: String) {
        var moves = inventedMoves(childId: childId)
        guard !moves.contains(name) else { return }
        moves.append(name)
        if let data = try? JSONEncoder().encode(moves) {
            defaults.set(data, forKey: key("invented", childId))
        }
    }

    func inventedMoves(childId: String) -> [String] {
        guard let data = defaults.data(forKey: key("invented", childId)) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func key(_ field: String, _ childId: String) -> String {
        "creativity_\(field)_\(childId)"
    }
}
