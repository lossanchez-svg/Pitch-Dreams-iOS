import Foundation

// The 5-second mistake reset (PLAYER_DEVELOPMENT_PLAN.md, Phase B1b).
//
// The biggest cause of "playing scared" is one bad touch snowballing.
// This is the "Breathing Under Pressure" lesson converted from a read
// into a rehearsable tool: breath in, slow breath out, say your cue word.
// Pure sequence data — the view animates it, tests can verify it.

struct ResetRoutine: Equatable {
    enum PhaseKind: String, Equatable {
        case breatheIn
        case breatheOut
        case cue
    }

    struct Phase: Equatable {
        let kind: PhaseKind
        let duration: TimeInterval
        let prompt: String
    }

    let cueWord: String

    static let defaultCueWords = ["Next ball", "Reset", "I'm still here"]

    init(cueWord: String = ResetRoutine.defaultCueWords[0]) {
        self.cueWord = cueWord
    }

    /// 4-in / 6-out breathing from the Breathing Under Pressure lesson,
    /// then the spoken cue that ends the reset.
    var phases: [Phase] {
        [
            Phase(kind: .breatheIn, duration: 4, prompt: "Breathe in through your nose"),
            Phase(kind: .breatheOut, duration: 6, prompt: "Slow breath out through your mouth"),
            Phase(kind: .cue, duration: 3, prompt: "Say it: \u{201C}\(cueWord)\u{201D}"),
        ]
    }

    var totalDuration: TimeInterval {
        phases.reduce(0) { $0 + $1.duration }
    }

    /// The phase active at `elapsed` seconds, with 0–1 progress inside it.
    /// Returns nil once the routine is over.
    func phase(at elapsed: TimeInterval) -> (index: Int, phase: Phase, progress: Double)? {
        guard elapsed >= 0 else { return nil }
        var start: TimeInterval = 0
        for (index, phase) in phases.enumerated() {
            let end = start + phase.duration
            if elapsed < end {
                return (index, phase, (elapsed - start) / phase.duration)
            }
            start = end
        }
        return nil
    }
}
