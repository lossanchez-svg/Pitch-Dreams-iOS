import Foundation

struct WeeklyRecap {
    let weekStarting: Date
    let sessionsCompleted: Int
    let totalMinutes: Int
    let currentStreak: Int
    let xpEarned: Int          // XP earned THIS WEEK
    let totalXP: Int           // lifetime total (for avatar stage)
    let avatarId: String?      // for rendering avatar on card
    let bestDrill: String?     // name of drill with highest score
    let personalBests: Int     // number of new PBs this week
    let improvementStat: String? // e.g., "Juggling +15% this month"
    /// Seven bools for M-T-W-T-F-S-S, true if trained that day.
    let weekdayActivity: [Bool]

    init(
        weekStarting: Date,
        sessionsCompleted: Int,
        totalMinutes: Int,
        currentStreak: Int,
        xpEarned: Int,
        totalXP: Int,
        avatarId: String?,
        bestDrill: String?,
        personalBests: Int,
        improvementStat: String?,
        weekdayActivity: [Bool] = Array(repeating: false, count: 7)
    ) {
        self.weekStarting = weekStarting
        self.sessionsCompleted = sessionsCompleted
        self.totalMinutes = totalMinutes
        self.currentStreak = currentStreak
        self.xpEarned = xpEarned
        self.totalXP = totalXP
        self.avatarId = avatarId
        self.bestDrill = bestDrill
        self.personalBests = personalBests
        self.improvementStat = improvementStat
        // Ensure exactly 7 entries; pad or trim defensively.
        if weekdayActivity.count == 7 {
            self.weekdayActivity = weekdayActivity
        } else if weekdayActivity.count > 7 {
            self.weekdayActivity = Array(weekdayActivity.prefix(7))
        } else {
            self.weekdayActivity = weekdayActivity + Array(repeating: false, count: 7 - weekdayActivity.count)
        }
    }

    var avatarStage: AvatarStage {
        XPCalculator.avatarStageForXP(totalXP)
    }

    var formattedMinutes: String {
        if totalMinutes < 60 { return "\(totalMinutes) min" }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStarting) ?? weekStarting
        return "\(formatter.string(from: weekStarting)) - \(formatter.string(from: end))"
    }
}
