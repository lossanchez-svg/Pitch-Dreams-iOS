import Foundation

actor XPStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getTotalXP(childId: String) -> Int {
        defaults.integer(forKey: "xp_total_\(childId)")
    }

    /// Add XP and return whether the avatar evolved.
    func addXP(_ amount: Int, childId: String) -> (
        newTotal: Int,
        evolved: Bool,
        oldStage: AvatarStage,
        newStage: AvatarStage
    ) {
        let oldTotal = getTotalXP(childId: childId)
        let oldStage = XPCalculator.avatarStageForXP(oldTotal)
        let newTotal = oldTotal + amount
        let newStage = XPCalculator.avatarStageForXP(newTotal)
        defaults.set(newTotal, forKey: "xp_total_\(childId)")
        return (newTotal, newStage != oldStage, oldStage, newStage)
    }

    func getXPHistory(childId: String) -> [XPEntry] {
        guard let data = defaults.data(forKey: "xp_history_\(childId)"),
              let entries = try? JSONDecoder().decode([XPEntry].self, from: data) else { return [] }
        return entries
    }

    func recordXPEntry(_ entry: XPEntry, childId: String) {
        var history = getXPHistory(childId: childId)
        history.append(entry)
        // Keep last 100 entries
        if history.count > 100 { history = Array(history.suffix(100)) }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: "xp_history_\(childId)")
        }
    }
}
