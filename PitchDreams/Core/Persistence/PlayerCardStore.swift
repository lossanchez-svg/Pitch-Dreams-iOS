import Foundation

/// Persists the child's Player Card customizations — archetype, displayed
/// stats, move loadout, club crest, frame. Stored per-child in UserDefaults
/// so siblings on one device each have their own card.
///
/// Stats themselves are NOT persisted here — they're derived on demand from
/// training activity via `StatComputer`, so they always reflect the latest
/// session log.
actor PlayerCardStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func get(childId: String) -> PlayerCard {
        guard let data = defaults.data(forKey: key(childId)),
              let card = try? JSONDecoder().decode(PlayerCard.self, from: data) else {
            return defaultCard(childId: childId)
        }
        return card
    }

    func save(_ card: PlayerCard) {
        guard let data = try? JSONEncoder().encode(card) else { return }
        defaults.set(data, forKey: key(card.childId))
    }

    func updateArchetype(_ archetype: PlayerArchetype, childId: String) {
        var card = get(childId: childId)
        card.archetype = archetype
        // Reset tagline to archetype default if user hadn't customized it.
        if card.archetypeTagline == nil {
            card.archetypeTagline = archetype.tagline
        }
        save(card)
    }

    func updateDisplayedStats(_ stats: [CardStat], childId: String) {
        var card = get(childId: childId)
        card.displayedStats = Array(stats.prefix(PlayerCard.displayedStatCount))
        save(card)
    }

    func updateMoveLoadout(_ moveIds: [String], childId: String) {
        var card = get(childId: childId)
        card.moveLoadout = Array(moveIds.prefix(PlayerCard.maxMoveLoadout))
        save(card)
    }

    func updateFrame(_ frame: CardFrame, childId: String) {
        var card = get(childId: childId)
        card.cardFrame = frame
        save(card)
    }

    func updateCrest(_ crest: ClubCrestDesign, childId: String) {
        var card = get(childId: childId)
        card.clubCrestDesign = crest
        save(card)
    }

    func updateTagline(_ tagline: String?, childId: String) {
        var card = get(childId: childId)
        card.archetypeTagline = tagline
        save(card)
    }

    /// Wipe the stored card for a child. Used by reset-progress flows.
    func clear(childId: String) {
        defaults.removeObject(forKey: key(childId))
    }

    // MARK: - Private

    private func key(_ childId: String) -> String { "player_card_\(childId)" }

    private func defaultCard(childId: String) -> PlayerCard {
        PlayerCard(
            childId: childId,
            archetype: .allrounder,
            displayedStats: [.speed, .touch, .vision, .workRate],
            moveLoadout: [],
            clubCrestDesign: .defaultDesign,
            cardFrame: .standard,
            archetypeTagline: nil  // nil = use archetype default; non-nil = user customized
        )
    }
}
