import Foundation

struct TacticalLesson: Identifiable {
    let id: String
    let title: String
    let track: String  // scanning, decision_chain, tempo
    let description: String
    let difficulty: String  // beginner, intermediate, advanced
    let steps: [String]
    let readingTimeMinutes: Int
}

enum TacticalLessonRegistry {
    static let all: [TacticalLesson] = [
        TacticalLesson(
            id: "3point-scan",
            title: "3-Point Scan",
            track: "scanning",
            description: "Learn to check three key zones before receiving the ball: behind you, to the sides, and in front. This habit gives you a mental picture of the field so you can make faster decisions.",
            difficulty: "beginner",
            steps: [
                "Before the ball arrives, look over your left shoulder to check for pressure behind you.",
                "Quickly glance to your right to identify open teammates or space.",
                "Check forward to see passing lanes and movement of teammates ahead.",
                "Receive the ball with your body already open to the best option.",
                "Practice scanning at least twice before every touch in training."
            ],
            readingTimeMinutes: 3
        ),
        TacticalLesson(
            id: "receive-decide-execute",
            title: "Receive-Decide-Execute",
            track: "decision_chain",
            description: "Break every moment on the ball into three clear steps: control the ball cleanly, choose your best action, and execute with confidence. This framework removes hesitation.",
            difficulty: "beginner",
            steps: [
                "Receive: Cushion the ball with a soft first touch into space away from pressure.",
                "Decide: In the split second after your touch, commit to pass, dribble, or shoot.",
                "Execute: Carry out your decision without second-guessing. Speed of action beats perfection.",
                "After each action, immediately reset and scan for the next cycle."
            ],
            readingTimeMinutes: 3
        ),
        TacticalLesson(
            id: "patience-in-possession",
            title: "Patience in Possession",
            track: "tempo",
            description: "Not every touch needs to be forward. Learn when to slow down, recycle possession, and wait for the right moment to attack. Controlling tempo is a sign of a mature player.",
            difficulty: "intermediate",
            steps: [
                "Recognize when no forward pass is on -- it is okay to play sideways or backward.",
                "Use short passes to move defenders out of position and create gaps.",
                "Count to two after receiving before committing to a pass to let the play develop.",
                "Watch for a teammate making a late run as the signal to accelerate.",
                "Practice keeping the ball for 10 consecutive passes in small-sided games."
            ],
            readingTimeMinutes: 4
        ),
        TacticalLesson(
            id: "check-your-shoulder",
            title: "Check Your Shoulder",
            track: "scanning",
            description: "The shoulder check is the simplest scanning habit and the most impactful. One quick glance over your shoulder before receiving tells you if you can turn or need to play safe.",
            difficulty: "beginner",
            steps: [
                "As the ball is traveling to you, glance over your back shoulder.",
                "If no defender is close, open your body and turn with your first touch.",
                "If a defender is tight, shield the ball and play it back or sideways.",
                "Practice the shoulder check every single time you receive in training.",
                "Aim for two shoulder checks per possession as a baseline."
            ],
            readingTimeMinutes: 3
        ),
        TacticalLesson(
            id: "press-triggers",
            title: "Press Triggers",
            track: "decision_chain",
            description: "Learn to recognize the signals that tell you when to press and when to hold. A well-timed press wins the ball; a mistimed one leaves a hole behind you.",
            difficulty: "intermediate",
            steps: [
                "Trigger 1: The opponent receives with a poor touch -- press immediately.",
                "Trigger 2: The opponent faces their own goal -- they have limited options, press the passing lanes.",
                "Trigger 3: A backward pass from the opponent -- the whole team shifts forward together.",
                "If no trigger is present, hold your position and stay compact.",
                "Communicate with teammates so you press as a unit, not alone."
            ],
            readingTimeMinutes: 4
        ),
        TacticalLesson(
            id: "third-man-run",
            title: "Third Man Run",
            track: "decision_chain",
            description: "The third man run involves three players working together: passer, receiver, and the runner who arrives late to exploit the space. It is one of the most effective patterns in attacking play.",
            difficulty: "advanced",
            steps: [
                "Player A passes to Player B, who is checking toward the ball.",
                "Player B receives and holds briefly, drawing a defender toward them.",
                "Player C (the third man) times a run into the space vacated by the defender.",
                "Player B plays a first-time or quick pass into the path of Player C.",
                "Practice the timing so Player C arrives in space just as the ball does."
            ],
            readingTimeMinutes: 5
        ),
        TacticalLesson(
            id: "switching-the-play",
            title: "Switching the Play",
            track: "tempo",
            description: "When the ball is on one side of the field and defenders shift over, the space opens on the opposite side. A quick switch of play exploits this width advantage.",
            difficulty: "intermediate",
            steps: [
                "Scan to identify when the defense has shifted heavily to one side.",
                "Look for a teammate in space on the far side of the field.",
                "Play a firm, driven pass or a diagonal to switch the point of attack.",
                "The receiving player should already be in position with an open body shape.",
                "After switching, the team should attack quickly before the defense can reorganize."
            ],
            readingTimeMinutes: 4
        ),
        TacticalLesson(
            id: "blind-side-movement",
            title: "Blind Side Movement",
            track: "scanning",
            description: "Moving into the blind side of a defender means getting into the space they cannot see without turning their head. This is how the best strikers find space in the box.",
            difficulty: "advanced",
            steps: [
                "Identify where the defender is looking -- usually at the ball.",
                "Move into the area behind or beside the defender that is out of their peripheral vision.",
                "Time your movement so you arrive in the blind spot just as the ball is played.",
                "Use a short, sharp burst of acceleration to separate from the marker.",
                "Practice starting your run from a standing position to disguise your intent."
            ],
            readingTimeMinutes: 5
        ),
        TacticalLesson(
            id: "controlling-the-tempo",
            title: "Controlling the Tempo",
            track: "tempo",
            description: "Great players speed the game up and slow it down on purpose. Learn to read when to accelerate play and when to take a breath and keep the ball.",
            difficulty: "advanced",
            steps: [
                "Speed up when: your team has a numerical advantage, the defense is disorganized, or a teammate is making a penetrating run.",
                "Slow down when: your team needs to recover shape, no forward option is available, or you are protecting a lead.",
                "Use your body language and touch weight to set the tempo for teammates.",
                "A quick one-touch pass signals acceleration; a controlled receive signals patience.",
                "Practice by alternating between fast-combination play and slow build-up in training games."
            ],
            readingTimeMinutes: 5
        ),
        TacticalLesson(
            id: "breathing-under-pressure",
            title: "Breathing Under Pressure",
            track: "tempo",
            description: "Mental composure is a tactical skill. Learn a breathing routine that helps you stay calm when the game speeds up, so you can think clearly under pressure.",
            difficulty: "beginner",
            steps: [
                "Before the game, take five deep breaths: inhale for 4 counts, exhale for 6 counts.",
                "During stoppages (throw-ins, goal kicks), use one breath cycle to reset mentally.",
                "If you make an error, take one slow exhale before the next action to clear the frustration.",
                "Focus on the next action only -- do not dwell on the previous mistake.",
                "Practice this breathing routine during training so it becomes automatic in matches."
            ],
            readingTimeMinutes: 3
        ),
    ]

    static func lesson(for id: String) -> TacticalLesson? {
        all.first { $0.id == id }
    }

    static func lessons(for track: String) -> [TacticalLesson] {
        all.filter { $0.track == track }
    }

    static var tracks: [String] {
        ["scanning", "decision_chain", "tempo"]
    }

    static func trackDisplayName(_ track: String) -> String {
        switch track {
        case "scanning": return "Scanning"
        case "decision_chain": return "Decision Chain"
        case "tempo": return "Tempo"
        default: return track.capitalized
        }
    }

    static func trackIcon(_ track: String) -> String {
        switch track {
        case "scanning": return "eye.fill"
        case "decision_chain": return "brain.fill"
        case "tempo": return "metronome.fill"
        default: return "book.fill"
        }
    }

    static func trackColor(_ track: String) -> String {
        switch track {
        case "scanning": return "cyan"
        case "decision_chain": return "purple"
        case "tempo": return "orange"
        default: return "blue"
        }
    }
}
