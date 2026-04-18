import Foundation

actor PersonalBestStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Check if a value beats the current personal best for a metric.
    /// Returns `true` if a new PB was set.
    func checkAndUpdate(metric: String, value: Int, childId: String) -> Bool {
        let key = "pb_\(metric)_\(childId)"
        let previous = defaults.integer(forKey: key)
        if value > previous {
            defaults.set(value, forKey: key)
            return true  // New PB!
        }
        return false
    }

    func getBest(metric: String, childId: String) -> Int {
        defaults.integer(forKey: "pb_\(metric)_\(childId)")
    }
}
