import Foundation

/// Derives `CardStats` from the archetype baseline plus training activity.
/// Stats are always computed — never persisted — so they reflect the most
/// recent sessions the moment the card loads.
///
/// Modifiers layered on top of the baseline:
///  - Training volume: every 50 sessions grants +1 to every stat (cap +10)
///  - Ball-mastery drills: +1 touch per 10 sessions (cap +8)
///  - First-touch drills:  +1 touch per 8 sessions (cap +6)
///  - Juggling drills:     +1 touch per 10 and +1 composure per 15 (cap 5)
///  - Shooting drills:     +1 shotPower per 8 sessions (cap +10)
///  - XP bonus:            every 500 total XP grants +1 workRate + +1 composure (cap +8)
/// All stats clamp to 30…99.
actor StatComputer {
    private let xpStore: XPStore

    init(xpStore: XPStore = XPStore()) {
        self.xpStore = xpStore
    }

    /// Compute stats from archetype + recent session log + XP context.
    func computeStats(
        for card: PlayerCard,
        sessions: [SessionLog]
    ) async -> CardStats {
        var stats = card.archetype.baselineStats

        // Volume boost across the board.
        let volumeBonus = min(10, sessions.count / 50)
        stats.speed += volumeBonus
        stats.touch += volumeBonus
        stats.vision += volumeBonus
        stats.shotPower += volumeBonus
        stats.workRate += volumeBonus
        stats.composure += volumeBonus

        // Discipline-specific boosts from session focus tags.
        let ballMastery = sessions.count { focusContains($0, "ball_mastery") }
        stats.touch += min(8, ballMastery / 10)

        let firstTouch = sessions.count { focusContains($0, "first_touch") }
        stats.touch += min(6, firstTouch / 8)

        let juggling = sessions.count { focusContains($0, "juggling") }
        stats.touch += min(5, juggling / 10)
        stats.composure += min(5, juggling / 15)

        let shooting = sessions.count { focusContains($0, "shooting") }
        stats.shotPower += min(10, shooting / 8)

        // XP-driven consistency bonus (workRate + composure).
        let totalXP = await xpStore.getTotalXP(childId: card.childId)
        let xpBonus = min(8, totalXP / 500)
        stats.workRate += xpBonus
        stats.composure += xpBonus

        return clamp(stats)
    }

    /// FIFA-style overall rating — weighted average of the 4 displayed stats.
    func overallRating(stats: CardStats, displayed: [CardStat]) -> Int {
        let values = displayed.map { stats.value(for: $0) }
        guard !values.isEmpty else { return 0 }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    // MARK: - Private

    private func clamp(_ stats: CardStats) -> CardStats {
        CardStats(
            speed:     min(99, max(30, stats.speed)),
            touch:     min(99, max(30, stats.touch)),
            vision:    min(99, max(30, stats.vision)),
            shotPower: min(99, max(30, stats.shotPower)),
            workRate:  min(99, max(30, stats.workRate)),
            composure: min(99, max(30, stats.composure))
        )
    }

    private func focusContains(_ session: SessionLog, _ keyword: String) -> Bool {
        (session.focus ?? "").lowercased().contains(keyword)
    }
}
