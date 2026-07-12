import Foundation

// Scan & Solve (PLAYER_DEVELOPMENT_PLAN.md, Phase B4a).
//
// Regular wall/juggling work trains the touch in a vacuum. Scan & Solve
// couples it to information the way a match does: the coach calls a random
// direction while the ball is moving, and the first touch has to go there.
// The app *speaks* the calls (AVSpeechSynthesizer output — this does not use
// the microphone, which A4 deliberately de-emphasized). The score is clean
// directional touches under command, not raw reps.

enum ScanCommand: String, CaseIterable, Equatable {
    case left
    case right
    case turn
    case stop

    /// What the coach voice calls out.
    var spoken: String {
        switch self {
        case .left: return "Left!"
        case .right: return "Right!"
        case .turn: return "Turn!"
        case .stop: return "Stop it dead!"
        }
    }

    var display: String {
        switch self {
        case .left: return "LEFT"
        case .right: return "RIGHT"
        case .turn: return "TURN"
        case .stop: return "STOP"
        }
    }

    var icon: String {
        switch self {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .turn: return "arrow.uturn.up"
        case .stop: return "hand.raised.fill"
        }
    }
}

/// How fast the calls come. Play-testing showed a fixed 6s left kids
/// standing around between plays — pace tiers keep the wall-ball rhythm
/// going for every age.
enum ScanPace: String, CaseIterable, Equatable {
    case steady
    case quick
    case blazing

    var interval: TimeInterval {
        switch self {
        case .steady: return 5
        case .quick: return 4
        case .blazing: return 3
        }
    }

    var label: String {
        switch self {
        case .steady: return "STEADY"
        case .quick: return "QUICK"
        case .blazing: return "BLAZING"
        }
    }

    var hint: String {
        switch self {
        case .steady: return "Learning the calls"
        case .quick: return "Match rhythm"
        case .blazing: return "No thinking time"
        }
    }
}

/// One round of calls. Pure sequence data — deterministic under a seed so
/// tests can pin the exact commands and timing; the view animates it.
struct ScanSolveRound: Equatable {
    let commands: [ScanCommand]
    /// Seconds between calls.
    let interval: TimeInterval
    /// "Get ready" seconds before the first call.
    let leadIn: TimeInterval

    static let defaultCount = 10
    static let defaultPace: ScanPace = .quick
    static let defaultInterval: TimeInterval = ScanPace.quick.interval
    static let defaultLeadIn: TimeInterval = 3

    enum Moment: Equatable {
        case leadIn(remaining: TimeInterval)
        case command(index: Int, command: ScanCommand)
        case finished
    }

    /// SplitMix64 — tiny seedable generator so rounds are testable.
    /// (`SystemRandomNumberGenerator` can't be seeded.)
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    /// No two consecutive identical calls — a repeat teaches nothing.
    static func generate(
        count: Int = defaultCount,
        interval: TimeInterval = defaultInterval,
        leadIn: TimeInterval = defaultLeadIn,
        seed: UInt64 = UInt64.random(in: 0..<UInt64.max)
    ) -> ScanSolveRound {
        var rng = SeededGenerator(state: seed)
        var commands: [ScanCommand] = []
        commands.reserveCapacity(count)
        while commands.count < count {
            let candidates = ScanCommand.allCases.filter { $0 != commands.last }
            commands.append(candidates.randomElement(using: &rng)!)
        }
        return ScanSolveRound(commands: commands, interval: interval, leadIn: leadIn)
    }

    var totalDuration: TimeInterval {
        leadIn + Double(commands.count) * interval
    }

    func moment(at elapsed: TimeInterval) -> Moment {
        if elapsed < leadIn {
            return .leadIn(remaining: leadIn - elapsed)
        }
        let index = Int((elapsed - leadIn) / interval)
        guard index < commands.count else { return .finished }
        return .command(index: index, command: commands[index])
    }
}
