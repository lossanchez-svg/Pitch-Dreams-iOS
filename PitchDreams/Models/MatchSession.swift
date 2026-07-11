import Foundation

// Match Mode (PLAYER_DEVELOPMENT_PLAN.md, Phase B3).
//
// Every psychological moment that matters happens in a match the app never
// sees. Match Mode closes that loop with a 90-second pre-match routine
// (proof → process goal → power cue → breath) and a post-match reflection
// about bravery and decisions — never goals scored or mistakes made.
// Process goals, not outcome goals, are what reduce performance anxiety.

struct MatchPrep: Codable, Equatable {
    let processGoal: String
    let powerCue: String
    let preppedAt: Date
}

struct MatchReflection: Codable, Equatable {
    /// The hard thing the kid tried — the input to the courage flywheel.
    let braveThingTried: String?
    let effortLevel: Int  // 1-5, same scale as QuickLog
    let decisionImProudOf: String?
    let reflectedAt: Date
}

/// All-taps presets — a kid mid-warmup shouldn't be typing.
enum MatchPresets {
    /// Process goals: things within the player's control, win or lose.
    static let processGoals = [
        "Be brave receiving on the half-turn",
        "Ask for the ball after a mistake",
        "Scan before every touch",
        "Try my move in a real 1v1",
        "Talk to my teammates all game",
        "Press hard on their bad touches",
    ]

    static let powerCues = [
        "I've done the work",
        "Next ball",
        "Play brave",
        "This is my pitch",
    ]

    /// Brave things worth banking, whatever the scoreboard said.
    static let braveThings = [
        "Asked for the ball after a mistake",
        "Took my defender on 1v1",
        "Tried my signature move",
        "Received on the half-turn",
        "Shot when I had the chance",
        "Organized my teammates",
    ]

    /// Decisions worth being proud of — process, not outcomes.
    static let proudDecisions = [
        "A pass that split the line",
        "Switched the play at the right time",
        "Pressed on the right trigger",
        "Stayed patient when it was blocked",
        "Reset fast after a bad touch",
    ]
}
