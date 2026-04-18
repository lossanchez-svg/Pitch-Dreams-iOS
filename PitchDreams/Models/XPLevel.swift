import Foundation

/// XP calculation engine. XP is the single currency driving avatar evolution.
/// There are NO separate tier names -- the visible progression is avatar stages
/// (Rookie -> Pro -> Legend) defined in Avatar.swift.
enum XPCalculator {

    // MARK: - XP Awards

    /// XP earned for completing a training session.
    static func xpForSession(duration: Int?, effortLevel: Int?, activityType: String?) -> Int {
        var xp = 0

        // Base XP: 10 XP per 5 minutes of training
        let minutes = duration ?? 10
        xp += (minutes / 5) * 10

        // Effort bonus: high effort earns more
        if let effort = effortLevel {
            xp += effort * 5  // effort is 1-10, so 5-50 bonus
        }

        // Activity type bonus
        switch activityType?.lowercased() {
        case "drill": xp += 15
        case "game", "match": xp += 25
        case "class", "team": xp += 20
        default: xp += 10
        }

        return max(10, xp) // minimum 10 XP per session
    }

    /// Bonus XP for reaching a streak milestone.
    static func xpForStreakMilestone(_ milestone: Int) -> Int {
        switch milestone {
        case 7:   return 50
        case 14:  return 100
        case 30:  return 250
        case 100: return 1000
        default:  return 25
        }
    }

    /// Bonus XP for a new personal best.
    static let xpForPersonalBest = 25

    // MARK: - Avatar Evolution Thresholds

    /// XP required to reach each avatar stage.
    /// These thresholds replace the old milestone-based and mission-XP-based
    /// triggers in AvatarStage.current().
    static func avatarStageForXP(_ totalXP: Int) -> AvatarStage {
        if totalXP >= xpForStage(.legend) { return .legend }
        if totalXP >= xpForStage(.pro) { return .pro }
        return .rookie
    }

    /// XP threshold for a given stage.
    static func xpForStage(_ stage: AvatarStage) -> Int {
        switch stage {
        case .rookie: return 0
        case .pro:    return 500   // ~2-3 weeks of regular training
        case .legend: return 2000  // ~2-3 months of regular training
        }
    }

    /// XP progress within the current stage, as fraction 0.0-1.0.
    static func progressToNextStage(_ totalXP: Int) -> (progress: Double, xpInStage: Int, xpNeeded: Int) {
        let currentStage = avatarStageForXP(totalXP)

        guard currentStage != .legend else {
            return (progress: 1.0, xpInStage: 0, xpNeeded: 0) // maxed out
        }

        let nextStage: AvatarStage = currentStage == .rookie ? .pro : .legend
        let currentThreshold = xpForStage(currentStage)
        let nextThreshold = xpForStage(nextStage)
        let xpInStage = totalXP - currentThreshold
        let xpNeeded = nextThreshold - currentThreshold
        let progress = Double(xpInStage) / Double(xpNeeded)

        return (progress: min(1.0, progress), xpInStage: xpInStage, xpNeeded: xpNeeded)
    }
}

struct XPEntry: Codable {
    let amount: Int
    let source: String  // "session", "drill", "first_touch", "streak_bonus", "personal_best"
    let date: Date
}
