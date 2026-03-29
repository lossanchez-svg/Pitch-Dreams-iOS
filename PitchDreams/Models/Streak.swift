import Foundation

struct StreakData: Codable {
    let freezes: Int
    let freezesUsed: Int
    let milestones: [Int]
}

struct FreezeCheckResult: Codable {
    let freezeApplied: Bool
    let freezesRemaining: Int
}

struct MilestoneResult: Codable {
    let recorded: Bool
    let freezeAwarded: Bool
}
