import Foundation

/// Generates a random mystery-box reward weighted by each type's drop rate.
/// Context-aware: reward types that make no sense for the current state
/// (e.g., moveAttempt with zero locked moves) are filtered out and the
/// weights re-normalized so the user still gets SOMETHING.
enum MysteryBoxEngine {

    /// Produce a reward for today's box. Caller is responsible for
    /// persisting it via `MysteryBoxStore.recordOpen`.
    static func generateReward(
        context: MysteryBoxContext,
        randomSource: () -> Double = { Double.random(in: 0..<1) }
    ) -> MysteryReward {
        let eligible = MysteryRewardType.allCases.filter { context.isEligible(for: $0) }
        guard !eligible.isEmpty else {
            // Safety net — should never hit since smallXP is always eligible.
            return buildReward(type: .smallXP, context: context)
        }

        let totalWeight = eligible.reduce(0.0) { $0 + $1.dropRate }
        let roll = randomSource() * totalWeight
        var cumulative = 0.0
        var selected: MysteryRewardType = eligible[0]
        for type in eligible {
            cumulative += type.dropRate
            if roll < cumulative {
                selected = type
                break
            }
        }
        return buildReward(type: selected, context: context)
    }

    /// Expose the eligible types + their normalized rates so the Settings
    /// "See mystery box odds" screen can render them transparently.
    static func publicOdds(context: MysteryBoxContext) -> [(type: MysteryRewardType, rate: Double)] {
        let eligible = MysteryRewardType.allCases.filter { context.isEligible(for: $0) }
        let total = eligible.reduce(0.0) { $0 + $1.dropRate }
        guard total > 0 else { return [] }
        return eligible.map { ($0, $0.dropRate / total) }
    }

    // MARK: - Private

    private static func buildReward(type: MysteryRewardType, context: MysteryBoxContext) -> MysteryReward {
        let now = Date()
        switch type {
        case .smallXP:
            return MysteryReward(id: UUID(), type: .smallXP, xpAmount: 25, cosmeticId: nil, moveAttemptMoveId: nil, openedAt: now)
        case .mediumXP:
            return MysteryReward(id: UUID(), type: .mediumXP, xpAmount: 50, cosmeticId: nil, moveAttemptMoveId: nil, openedAt: now)
        case .moveAttempt:
            let moveId = context.lockedMoveIds.randomElement() ?? "move-scissor"
            return MysteryReward(id: UUID(), type: .moveAttempt, xpAmount: nil, cosmeticId: nil, moveAttemptMoveId: moveId, openedAt: now)
        case .feverTime:
            return MysteryReward(id: UUID(), type: .feverTime, xpAmount: nil, cosmeticId: nil, moveAttemptMoveId: nil, openedAt: now)
        case .cosmeticDrop:
            let cosmeticId = context.availableCosmeticIds.randomElement() ?? "color_orange"
            return MysteryReward(id: UUID(), type: .cosmeticDrop, xpAmount: nil, cosmeticId: cosmeticId, moveAttemptMoveId: nil, openedAt: now)
        case .bonusShield:
            return MysteryReward(id: UUID(), type: .bonusShield, xpAmount: nil, cosmeticId: nil, moveAttemptMoveId: nil, openedAt: now)
        case .mysteryReward:
            return MysteryReward(id: UUID(), type: .mysteryReward, xpAmount: 150, cosmeticId: nil, moveAttemptMoveId: nil, openedAt: now)
        case .legendaryDrop:
            return MysteryReward(id: UUID(), type: .legendaryDrop, xpAmount: 500, cosmeticId: "frame_mysteryBoxRare", moveAttemptMoveId: nil, openedAt: now)
        }
    }
}

/// Runtime context for reward-type eligibility. Captured once per tap so the
/// weighted random doesn't race against mutating state.
struct MysteryBoxContext: Equatable {
    /// IDs of moves the child hasn't mastered yet. Empty → `.moveAttempt`
    /// gets filtered out of the roll.
    let lockedMoveIds: [String]

    /// Cosmetic IDs the user hasn't unlocked yet. Empty → `.cosmeticDrop`
    /// filtered.
    let availableCosmeticIds: [String]

    /// True when the child is at the shield cap. Blocks `.bonusShield`.
    let streakShieldsMaxed: Bool

    func isEligible(for type: MysteryRewardType) -> Bool {
        switch type {
        case .moveAttempt:
            return !lockedMoveIds.isEmpty
        case .bonusShield:
            return !streakShieldsMaxed
        case .cosmeticDrop:
            return !availableCosmeticIds.isEmpty
        default:
            return true
        }
    }
}
