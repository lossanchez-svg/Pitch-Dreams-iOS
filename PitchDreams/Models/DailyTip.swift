import Foundation

/// A short daily nudge surfaced on the child home dashboard. Categories give
/// the tip a visual tag so kids can expect the kind of advice they're getting.
struct DailyTip: Identifiable, Equatable {
    let id: String
    let category: TipCategory
    let text: String
}

enum TipCategory: String, CaseIterable {
    case technical
    case mental
    case recovery
    case tactical

    var displayName: String {
        switch self {
        case .technical: return "Technical"
        case .mental:    return "Mental"
        case .recovery:  return "Recovery"
        case .tactical:  return "Tactical"
        }
    }

    var emoji: String {
        switch self {
        case .technical: return "💪"
        case .mental:    return "🧠"
        case .recovery:  return "🛌"
        case .tactical:  return "🎯"
        }
    }

    var accentColorHex: String {
        switch self {
        case .technical: return "#FF6B2C"  // orange
        case .mental:    return "#A855F7"  // purple
        case .recovery:  return "#46E5F8"  // cyan
        case .tactical:  return "#FFE9BD"  // gold
        }
    }
}
