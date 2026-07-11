import Foundation

// Confidence Evidence Bank (PLAYER_DEVELOPMENT_PLAN.md, Phase B1a).
//
// Self-efficacy is belief backed by evidence, and the #1 source of it is
// mastery experience the athlete can point to. Everything here is a
// *re-presentation of data the app already stores* — no new collection.

/// One line of proof, rendered as a narrative sentence, not a chart.
struct EvidenceLine: Identifiable, Equatable {
    enum Kind: String {
        case mastery       // "You've mastered the Scissor."
        case record        // "Your juggling best: 47 in a row."
        case consistency   // "12 days straight. That's not luck."
        case volume        // "31 training sessions logged."
        case courage       // reserved for the Match Mode bravery flywheel
        case starter       // encouraging line for brand-new players
    }

    let kind: Kind
    let text: String

    var id: String { "\(kind.rawValue)-\(text)" }

    /// SF Symbol per evidence kind, used by `EvidenceBankView`.
    var icon: String {
        switch kind {
        case .mastery:     return "star.circle.fill"
        case .record:      return "trophy.fill"
        case .consistency: return "flame.fill"
        case .volume:      return "chart.bar.fill"
        case .courage:     return "bolt.heart.fill"
        case .starter:     return "sparkles"
        }
    }
}

/// Everything the Evidence Bank knows about one player, assembled by
/// `ConfidenceViewModel` from existing stores.
struct ConfidenceSnapshot: Equatable {
    var masteredMoveNames: [String] = []
    var inProgressMoveNames: [String] = []
    var personalBests: [(label: String, value: Int)] = []
    var currentStreak: Int = 0
    var totalSessions: Int = 0
    /// True when totalSessions hit the fetch cap, so copy can say "30+".
    var sessionCountIsFloor: Bool = false
    /// Matches where the kid banked a brave play (Match Mode, Phase B3).
    var bravePlaysLogged: Int = 0

    static func == (lhs: ConfidenceSnapshot, rhs: ConfidenceSnapshot) -> Bool {
        lhs.masteredMoveNames == rhs.masteredMoveNames &&
        lhs.inProgressMoveNames == rhs.inProgressMoveNames &&
        lhs.personalBests.map(\.label) == rhs.personalBests.map(\.label) &&
        lhs.personalBests.map(\.value) == rhs.personalBests.map(\.value) &&
        lhs.currentStreak == rhs.currentStreak &&
        lhs.totalSessions == rhs.totalSessions &&
        lhs.sessionCountIsFloor == rhs.sessionCountIsFloor &&
        lhs.bravePlaysLogged == rhs.bravePlaysLogged
    }

    /// Render the snapshot as narrative lines. Never returns an empty list —
    /// a brand-new player gets an encouraging starter line, because an empty
    /// "evidence bank" would prove the opposite of what this screen is for.
    var evidenceLines: [EvidenceLine] {
        var lines: [EvidenceLine] = []

        if !masteredMoveNames.isEmpty {
            let names = Self.joinNames(masteredMoveNames)
            let verb = masteredMoveNames.count == 1 ? "You've mastered the \(names)." : "You've mastered the \(names)."
            lines.append(EvidenceLine(kind: .mastery, text: verb))
        } else if !inProgressMoveNames.isEmpty {
            lines.append(EvidenceLine(
                kind: .mastery,
                text: "You're building the \(Self.joinNames(inProgressMoveNames)) right now."
            ))
        }

        for pb in personalBests where pb.value > 0 {
            lines.append(EvidenceLine(kind: .record, text: "\(pb.label) best: \(pb.value). You set that."))
        }

        if currentStreak >= 3 {
            lines.append(EvidenceLine(
                kind: .consistency,
                text: "\(currentStreak) days in a row. That's not luck — that's training."
            ))
        }

        if totalSessions >= 5 {
            let count = sessionCountIsFloor ? "\(totalSessions)+" : "\(totalSessions)"
            lines.append(EvidenceLine(
                kind: .volume,
                text: "\(count) sessions logged. Every one of them is still in your feet."
            ))
        }

        if bravePlaysLogged >= 1 {
            let text = bravePlaysLogged == 1
                ? "You tried something brave in a real match. That's how it starts."
                : "\(bravePlaysLogged) matches where you tried something brave. You don't play scared."
            lines.append(EvidenceLine(kind: .courage, text: text))
        }

        if lines.isEmpty {
            lines.append(EvidenceLine(
                kind: .starter,
                text: "Your story starts today. Every session you log becomes proof you can point to."
            ))
        }

        return lines
    }

    /// "Scissor", "Scissor and Body Feint", "Scissor, Body Feint, and La Croqueta"
    static func joinNames(_ names: [String]) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return "\(names[0]) and \(names[1])"
        default:
            let head = names.dropLast().joined(separator: ", ")
            return "\(head), and \(names.last!)"
        }
    }
}
