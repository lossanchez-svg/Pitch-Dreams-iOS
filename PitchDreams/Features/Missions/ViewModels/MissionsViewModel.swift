import Foundation
import Combine

/// Client-side weekly missions store. v1 is UserDefaults-backed and never talks to the server.
/// A singleton keeps wiring simple — every feature that records an event reaches in via `.shared`.
@MainActor
final class MissionsViewModel: ObservableObject {
    static let shared = MissionsViewModel()

    @Published private(set) var weeklyMissions: [MissionInstance] = []
    @Published private(set) var localMissionXP: Int = 0
    /// Set when a mission completes — views observe this to show the MissionCompleteModal.
    @Published var lastCompleted: Mission?

    private let defaults: UserDefaults
    private var currentChildId: String?
    private var currentWeekKey: String = MissionRegistry.weekKey()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Load

    /// Generate this week's missions for the child and hydrate progress from UserDefaults.
    func load(childId: String, date: Date = Date()) {
        let weekKey = MissionRegistry.weekKey(for: date)
        currentChildId = childId
        currentWeekKey = weekKey

        let missions = MissionRegistry.weeklyMissions(childId: childId, weekKey: weekKey)
        weeklyMissions = missions.map { mission in
            let progress = defaults.integer(forKey: progressKey(childId: childId, weekKey: weekKey, missionId: mission.id))
            return MissionInstance(
                mission: mission,
                progress: min(progress, mission.targetCount),
                isCompleted: progress >= mission.targetCount
            )
        }
        localMissionXP = defaults.integer(forKey: xpKey(childId: childId))
    }

    // MARK: - Recording

    /// Record an in-app event. Increments any matching (non-completed) missions.
    /// Safe to call from any feature path after its primary save succeeds.
    func recordEvent(_ event: MissionEventType, count: Int = 1, childId: String) {
        // If the caller is a different child than what's loaded, refresh first.
        if currentChildId != childId {
            load(childId: childId)
        }
        let weekKey = currentWeekKey
        guard !weeklyMissions.isEmpty else { return }

        var newlyCompleted: Mission?
        var xpGained = 0

        for index in weeklyMissions.indices {
            var instance = weeklyMissions[index]
            guard !instance.isCompleted else { continue }
            guard instance.mission.eventType.matches(incoming: event, count: count) else { continue }

            instance.progress = min(instance.progress + 1, instance.mission.targetCount)
            defaults.set(instance.progress, forKey: progressKey(childId: childId, weekKey: weekKey, missionId: instance.mission.id))

            if instance.progress >= instance.mission.targetCount {
                instance.isCompleted = true
                xpGained += instance.mission.xpReward
                if newlyCompleted == nil {
                    newlyCompleted = instance.mission
                }
                Log.ui.info("Mission complete: \(instance.mission.id, privacy: .public) (+\(instance.mission.xpReward, privacy: .public) XP)")
            } else {
                Log.ui.info("Mission progress: \(instance.mission.id, privacy: .public) \(instance.progress, privacy: .public)/\(instance.mission.targetCount, privacy: .public)")
            }
            weeklyMissions[index] = instance
        }

        if xpGained > 0 {
            localMissionXP += xpGained
            defaults.set(localMissionXP, forKey: xpKey(childId: childId))
        }
        if let done = newlyCompleted {
            lastCompleted = done
        }
    }

    // MARK: - Helpers

    /// Days remaining until the next ISO-week rollover (Monday 00:00).
    func daysUntilReset(from date: Date = Date(), calendar: Calendar = .current) -> Int {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        guard let next = cal.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, weekday: 2),
            matchingPolicy: .nextTime
        ) else { return 7 }
        let days = cal.dateComponents([.day], from: date, to: next).day ?? 7
        return max(1, days)
    }

    private func progressKey(childId: String, weekKey: String, missionId: String) -> String {
        "mission_progress_\(childId)_\(weekKey)_\(missionId)"
    }

    private func xpKey(childId: String) -> String {
        "mission_xp_\(childId)"
    }
}
