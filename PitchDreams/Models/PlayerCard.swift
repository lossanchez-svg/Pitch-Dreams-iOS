import Foundation

/// The player's identity card — their permanent, shareable digital
/// representation. Lives on disk (`PlayerCardStore`) and is re-rendered
/// with live stats / avatar / moves at view time.
struct PlayerCard: Codable, Equatable {
    let childId: String
    var archetype: PlayerArchetype
    var displayedStats: [CardStat]        // 4 of 6 to show on the front
    var moveLoadout: [String]              // up to 4 Signature Move IDs
    var clubCrestDesign: ClubCrestDesign
    var cardFrame: CardFrame
    var archetypeTagline: String?

    static let maxMoveLoadout = 4
    static let displayedStatCount = 4

    /// Tagline the card should actually display — custom if set, otherwise
    /// the current archetype's built-in line. Views should prefer this over
    /// reading `archetypeTagline` directly so they never show a blank.
    var effectiveTagline: String {
        archetypeTagline ?? archetype.tagline
    }
}

// MARK: - Archetype

enum PlayerArchetype: String, Codable, CaseIterable, Identifiable {
    case speedster
    case playmaker
    case wall
    case magician
    case finisher
    case engine
    case sweeper
    case allrounder

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .speedster:  return "Speedster"
        case .playmaker:  return "Playmaker"
        case .wall:       return "The Wall"
        case .magician:   return "Magician"
        case .finisher:   return "Finisher"
        case .engine:     return "Engine"
        case .sweeper:    return "Sweeper"
        case .allrounder: return "All-Rounder"
        }
    }

    /// Archetype accent color — drives the card's frame gradient and
    /// stat-icon tint so different archetypes feel visually distinct.
    var accentColorHex: String {
        switch self {
        case .speedster:  return "#FF6B2C"
        case .playmaker:  return "#46E5F8"
        case .wall:       return "#8B5CF6"
        case .magician:   return "#E879F9"
        case .finisher:   return "#EF4444"
        case .engine:     return "#10B981"
        case .sweeper:    return "#3B82F6"
        case .allrounder: return "#FFE9BD"
        }
    }

    var tagline: String {
        switch self {
        case .speedster:  return "Fast feet, faster brain."
        case .playmaker:  return "Vision moves the team."
        case .wall:       return "Nothing gets through."
        case .magician:   return "Make the ball obey."
        case .finisher:   return "When it matters, I score."
        case .engine:     return "I run all day."
        case .sweeper:    return "Read the game ahead."
        case .allrounder: return "Do a little of everything."
        }
    }

    /// Baseline stats before training modifiers are applied.
    /// Numbers are archetype shape, not absolute values — `StatComputer`
    /// layers volume + discipline-specific bonuses on top.
    var baselineStats: CardStats {
        switch self {
        case .speedster:  return CardStats(speed: 90, touch: 65, vision: 60, shotPower: 70, workRate: 75, composure: 55)
        case .playmaker:  return CardStats(speed: 70, touch: 88, vision: 92, shotPower: 65, workRate: 75, composure: 78)
        case .wall:       return CardStats(speed: 65, touch: 68, vision: 75, shotPower: 60, workRate: 92, composure: 88)
        case .magician:   return CardStats(speed: 72, touch: 94, vision: 88, shotPower: 68, workRate: 70, composure: 82)
        case .finisher:   return CardStats(speed: 80, touch: 78, vision: 70, shotPower: 94, workRate: 65, composure: 82)
        case .engine:     return CardStats(speed: 78, touch: 75, vision: 80, shotPower: 70, workRate: 95, composure: 75)
        case .sweeper:    return CardStats(speed: 70, touch: 75, vision: 90, shotPower: 62, workRate: 85, composure: 92)
        case .allrounder: return CardStats(speed: 75, touch: 75, vision: 75, shotPower: 75, workRate: 75, composure: 75)
        }
    }
}

// MARK: - Stats

struct CardStats: Codable, Equatable {
    var speed: Int
    var touch: Int
    var vision: Int
    var shotPower: Int
    var workRate: Int
    var composure: Int

    func value(for stat: CardStat) -> Int {
        switch stat {
        case .speed:      return speed
        case .touch:      return touch
        case .vision:     return vision
        case .shotPower:  return shotPower
        case .workRate:   return workRate
        case .composure:  return composure
        }
    }
}

enum CardStat: String, Codable, CaseIterable, Identifiable {
    case speed, touch, vision, shotPower, workRate, composure

    var id: String { rawValue }

    /// 3-letter label shown on the card face (FIFA style).
    var displayName: String {
        switch self {
        case .speed:     return "SPD"
        case .touch:     return "TCH"
        case .vision:    return "VIS"
        case .shotPower: return "SHT"
        case .workRate:  return "WRK"
        case .composure: return "COM"
        }
    }

    var longName: String {
        switch self {
        case .speed:     return "Speed"
        case .touch:     return "Touch"
        case .vision:    return "Vision"
        case .shotPower: return "Shot Power"
        case .workRate:  return "Work Rate"
        case .composure: return "Composure"
        }
    }

    /// SF Symbol name for the stat icon.
    var iconSymbol: String {
        switch self {
        case .speed:     return "bolt.fill"
        case .touch:     return "hand.tap.fill"
        case .vision:    return "eye.fill"
        case .shotPower: return "target"
        case .workRate:  return "flame.fill"
        case .composure: return "leaf.fill"
        }
    }
}

// MARK: - Club / crest

struct ClubCrestDesign: Codable, Equatable {
    var primaryColorHex: String
    var secondaryColorHex: String
    var crestPatternId: String   // "stripes", "chevron", "solid", "split"
    var crestSymbolId: String    // SF Symbol name

    static let defaultDesign = ClubCrestDesign(
        primaryColorHex: "#FF6B2C",
        secondaryColorHex: "#0C1322",
        crestPatternId: "stripes",
        crestSymbolId: "star.fill"
    )
}

enum CardFrame: String, Codable, CaseIterable, Identifiable {
    case standard
    case bronze
    case silver
    case gold
    case legendary
    case mysteryBoxRare
    case founders

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:       return "Standard"
        case .bronze:         return "Bronze"
        case .silver:         return "Silver"
        case .gold:           return "Gold"
        case .legendary:      return "Legendary"
        case .mysteryBoxRare: return "Platinum Rare"
        case .founders:       return "Founders"
        }
    }

    var isUnlockedByDefault: Bool { self == .standard }
}
