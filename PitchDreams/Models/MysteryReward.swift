import Foundation

/// One of the daily-mystery-box reward categories. Drop rates are
/// transparent in Settings per the ethical-positioning rule.
enum MysteryRewardType: String, Codable, CaseIterable {
    case smallXP         // +25 XP
    case mediumXP        // +50 XP
    case moveAttempt     // free drill for a locked move
    case feverTime       // 15 min of 3x XP
    case cosmeticDrop    // card frame / color / celebration
    case bonusShield     // extra streak shield
    case mysteryReward   // medium-tier XP + cosmetic combo
    case legendaryDrop   // very rare

    var displayName: String {
        switch self {
        case .smallXP:        return "+25 XP"
        case .mediumXP:       return "+50 XP"
        case .moveAttempt:    return "Free Move Attempt"
        case .feverTime:      return "Fever Time"
        case .cosmeticDrop:   return "Cosmetic Unlock"
        case .bonusShield:    return "Bonus Shield"
        case .mysteryReward:  return "Mystery Reward"
        case .legendaryDrop:  return "Legendary Drop"
        }
    }

    /// Weighted drop rate. Sum of all active rates ≈ 1.0; contextual filters
    /// in `MysteryBoxContext` may remove types at runtime (e.g., skip
    /// moveAttempt if every move is mastered) so the engine re-normalizes.
    var dropRate: Double {
        switch self {
        case .smallXP:        return 0.30
        case .mediumXP:       return 0.20
        case .moveAttempt:    return 0.15
        case .feverTime:      return 0.10
        case .cosmeticDrop:   return 0.10
        case .bonusShield:    return 0.08
        case .mysteryReward:  return 0.05
        case .legendaryDrop:  return 0.02
        }
    }

    /// Rarity tier for UI treatment on the reveal screen.
    var rarity: MoveRarity {
        switch self {
        case .smallXP, .mediumXP, .bonusShield:     return .common
        case .moveAttempt, .feverTime, .cosmeticDrop: return .rare
        case .mysteryReward:                        return .epic
        case .legendaryDrop:                        return .legendary
        }
    }
}

/// A specific reward the user received on a given day.
struct MysteryReward: Codable, Equatable, Identifiable {
    let id: UUID
    let type: MysteryRewardType
    let xpAmount: Int?                // set for XP rewards
    let cosmeticId: String?            // set for cosmetic drops
    let moveAttemptMoveId: String?     // set for moveAttempt
    let openedAt: Date
}
