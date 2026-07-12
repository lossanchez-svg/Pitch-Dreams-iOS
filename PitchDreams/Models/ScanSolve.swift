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

/// How fast the calls come. The base state of a round is PLAYING, not
/// waiting: the kid keeps a continuous wall-ball rhythm and calls drop in
/// at jittered moments inside the pace's gap range. Fixed intervals felt
/// unnatural in play-testing (standing over the ball waiting for a call);
/// random gaps also force real listening — a metronome can be counted.
enum ScanPace: String, CaseIterable, Equatable {
    case steady
    case quick
    case blazing

    /// Bounds for the random gap between calls, in seconds.
    /// `minGap` stays >= `ScanSolveRound.callDisplayDuration` so a call
    /// never clips the next one off the screen.
    var minGap: TimeInterval {
        switch self {
        case .steady: return 4
        case .quick: return 3
        case .blazing: return 2.5
        }
    }

    var maxGap: TimeInterval {
        switch self {
        case .steady: return 7
        case .quick: return 5.5
        case .blazing: return 4
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
    /// Absolute call times in seconds from round start; strictly increasing.
    let callTimes: [TimeInterval]
    /// Rhythm warm-up seconds before the first call.
    let leadIn: TimeInterval

    static let defaultCount = 10
    static let defaultPace: ScanPace = .quick
    /// "Get your rhythm going" seconds before the first call can land.
    static let defaultLeadIn: TimeInterval = 5
    /// Seconds a call stays on screen before returning to the rhythm prompt.
    static let callDisplayDuration: TimeInterval = 2.5

    enum Moment: Equatable {
        case leadIn(remaining: TimeInterval)
        /// Between calls — the kid keeps passing; the next call is pending.
        case rhythm(nextIndex: Int)
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

    /// No two consecutive identical calls — a repeat teaches nothing — and
    /// gaps between calls are drawn uniformly from the pace's range so the
    /// kid has to actually listen instead of counting a metronome.
    static func generate(
        count: Int = defaultCount,
        pace: ScanPace = defaultPace,
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

        var callTimes: [TimeInterval] = []
        callTimes.reserveCapacity(count)
        var t = leadIn
        for i in 0..<count {
            if i > 0 {
                let fraction = Double(rng.next() % 1_000_000) / 1_000_000
                t += pace.minGap + fraction * (pace.maxGap - pace.minGap)
            }
            callTimes.append(t)
        }

        return ScanSolveRound(commands: commands, callTimes: callTimes, leadIn: leadIn)
    }

    var totalDuration: TimeInterval {
        (callTimes.last ?? leadIn) + Self.callDisplayDuration
    }

    func moment(at elapsed: TimeInterval) -> Moment {
        if elapsed < leadIn {
            return .leadIn(remaining: leadIn - elapsed)
        }
        // Last call whose time has passed, if any.
        var current = -1
        for (i, time) in callTimes.enumerated() {
            if elapsed >= time { current = i } else { break }
        }
        if current == -1 {
            return .rhythm(nextIndex: 0)
        }
        if elapsed < callTimes[current] + Self.callDisplayDuration {
            return .command(index: current, command: commands[current])
        }
        if current + 1 < callTimes.count {
            return .rhythm(nextIndex: current + 1)
        }
        return .finished
    }
}
