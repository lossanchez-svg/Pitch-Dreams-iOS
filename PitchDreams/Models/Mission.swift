import Foundation

/// Category of in-app event that can advance a mission's progress.
/// `.wallBallReps` and `.jugglingTaps` carry a minimum threshold — a single drill
/// that hits the threshold counts as 1 progress tick toward the mission.
enum MissionEventType: Hashable, Codable {
    case sessionLogged
    case wallBallReps(min: Int)
    case jugglingTaps(min: Int)
    case lessonRead
    case checkInCompleted
    case firstTouchDrillCompleted

    /// Stable string used to persist progress in UserDefaults and compare event kinds
    /// for progress matching (ignoring associated values).
    var storageKey: String {
        switch self {
        case .sessionLogged: return "sessionLogged"
        case .wallBallReps(let min): return "wallBallReps_\(min)"
        case .jugglingTaps(let min): return "jugglingTaps_\(min)"
        case .lessonRead: return "lessonRead"
        case .checkInCompleted: return "checkInCompleted"
        case .firstTouchDrillCompleted: return "firstTouchDrillCompleted"
        }
    }

    /// Does an incoming event (from the app) match this mission's trigger?
    /// For threshold events, the incoming count must meet the minimum.
    func matches(incoming: MissionEventType, count: Int) -> Bool {
        switch (self, incoming) {
        case (.sessionLogged, .sessionLogged),
             (.lessonRead, .lessonRead),
             (.checkInCompleted, .checkInCompleted),
             (.firstTouchDrillCompleted, .firstTouchDrillCompleted):
            return true
        case (.wallBallReps(let required), .wallBallReps):
            return count >= required
        case (.jugglingTaps(let required), .jugglingTaps):
            return count >= required
        default:
            return false
        }
    }
}

/// A mission template. Combined with per-child progress it becomes a `MissionInstance`.
struct Mission: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let targetCount: Int
    let eventType: MissionEventType
    let xpReward: Int
    let iconSystemName: String
}

/// A mission bound to the current child/week along with the current progress.
struct MissionInstance: Identifiable {
    let mission: Mission
    var progress: Int
    var isCompleted: Bool

    var id: String { mission.id }
    var progressFraction: Double {
        guard mission.targetCount > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(mission.targetCount))
    }
}

/// Registry of all possible weekly mission templates, plus deterministic weekly selection.
enum MissionRegistry {
    static let all: [Mission] = [
        // Session volume
        Mission(id: "log_3_sessions",
                title: "Log 3 sessions",
                description: "Train 3 times this week — anything counts.",
                targetCount: 3,
                eventType: .sessionLogged,
                xpReward: 20,
                iconSystemName: "figure.run"),
        Mission(id: "log_5_sessions",
                title: "5-session grind",
                description: "Put in 5 training sessions this week.",
                targetCount: 5,
                eventType: .sessionLogged,
                xpReward: 35,
                iconSystemName: "flame.fill"),

        // Juggling
        Mission(id: "juggle_50_twice",
                title: "50-tap juggler",
                description: "Hit 50+ juggles in two separate drills.",
                targetCount: 2,
                eventType: .jugglingTaps(min: 50),
                xpReward: 25,
                iconSystemName: "soccerball"),
        Mission(id: "juggle_100_once",
                title: "Century club",
                description: "Hit 100 juggles in a single drill.",
                targetCount: 1,
                eventType: .jugglingTaps(min: 100),
                xpReward: 40,
                iconSystemName: "soccerball.inverse"),
        Mission(id: "juggle_25_three",
                title: "Steady juggler",
                description: "Three drills with 25+ juggles each.",
                targetCount: 3,
                eventType: .jugglingTaps(min: 25),
                xpReward: 20,
                iconSystemName: "soccerball"),

        // Wall ball
        Mission(id: "wall_30_twice",
                title: "Wall warrior",
                description: "Two wall-ball drills with 30+ reps.",
                targetCount: 2,
                eventType: .wallBallReps(min: 30),
                xpReward: 25,
                iconSystemName: "rectangle.portrait.and.arrow.right"),
        Mission(id: "wall_50_once",
                title: "Fifty off the wall",
                description: "Hit 50 wall-ball reps in a single drill.",
                targetCount: 1,
                eventType: .wallBallReps(min: 50),
                xpReward: 30,
                iconSystemName: "rectangle.portrait.and.arrow.right.fill"),

        // Lessons
        Mission(id: "read_2_lessons",
                title: "Student of the game",
                description: "Finish reading 2 tactical lessons.",
                targetCount: 2,
                eventType: .lessonRead,
                xpReward: 20,
                iconSystemName: "book.fill"),
        Mission(id: "read_4_lessons",
                title: "Film room",
                description: "Finish reading 4 tactical lessons.",
                targetCount: 4,
                eventType: .lessonRead,
                xpReward: 40,
                iconSystemName: "books.vertical.fill"),

        // Check-ins
        Mission(id: "checkin_5",
                title: "Daily check-in",
                description: "Check in before training 5 times.",
                targetCount: 5,
                eventType: .checkInCompleted,
                xpReward: 20,
                iconSystemName: "heart.text.square.fill"),
        Mission(id: "checkin_3",
                title: "Tuned in",
                description: "Complete 3 pre-training check-ins.",
                targetCount: 3,
                eventType: .checkInCompleted,
                xpReward: 15,
                iconSystemName: "heart.text.square"),

        // First Touch drills
        Mission(id: "first_touch_3",
                title: "Touch tune-up",
                description: "Finish 3 First Touch drills.",
                targetCount: 3,
                eventType: .firstTouchDrillCompleted,
                xpReward: 20,
                iconSystemName: "hand.tap.fill"),
        Mission(id: "first_touch_6",
                title: "Touch obsessed",
                description: "Finish 6 First Touch drills.",
                targetCount: 6,
                eventType: .firstTouchDrillCompleted,
                xpReward: 35,
                iconSystemName: "hand.tap"),
    ]

    /// Stable ISO-week key of the form "2026-W15" for a given date.
    static func weekKey(for date: Date = Date(), calendar: Calendar = .iso8601) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        return String(format: "%04d-W%02d", year, week)
    }

    /// Deterministic pick of 3 missions for (childId, weekKey). Same inputs → same 3 missions.
    static func weeklyMissions(childId: String, weekKey: String) -> [Mission] {
        var rng = SeededRNG(seed: stableSeed(childId: childId, weekKey: weekKey))
        var pool = all
        var picked: [Mission] = []
        let count = min(3, pool.count)
        for _ in 0..<count {
            let idx = Int(rng.next() % UInt64(pool.count))
            picked.append(pool.remove(at: idx))
        }
        return picked
    }

    /// Deterministic FNV-1a hash so results are reproducible across Swift versions
    /// (`String.hashValue` is salted and not stable across launches).
    private static func stableSeed(childId: String, weekKey: String) -> UInt64 {
        let input = "\(childId)|\(weekKey)"
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}

/// Tiny SplitMix64 PRNG — deterministic and reproducible.
struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid the zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private extension Calendar {
    static let iso8601: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()
}
