import Foundation

// Creativity Lab (PLAYER_DEVELOPMENT_PLAN.md, Phase B4b).
//
// Everything else in the app rewards repetition; creativity needs the
// opposite. These challenges apply differential learning — never do the
// same rep twice — and the score IS the variety. Youth players are
// over-coached into sameness; this room rewards inventing.

struct CreativityChallenge: Identifiable, Equatable {
    let id: String
    let title: String
    let prompt: String
    /// Age-adapted prompt (≤11). Falls back to `prompt`.
    let promptYoung: String?
    /// How many *different* ways complete the challenge.
    let varietyTarget: Int
    /// What a tap counts: "ways", "body parts", "surfaces"...
    let unit: String
    let icon: String
    /// Invention challenges end with naming the new move.
    let isInvention: Bool

    init(
        id: String,
        title: String,
        prompt: String,
        promptYoung: String? = nil,
        varietyTarget: Int,
        unit: String,
        icon: String,
        isInvention: Bool = false
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.promptYoung = promptYoung
        self.varietyTarget = varietyTarget
        self.unit = unit
        self.icon = icon
        self.isInvention = isInvention
    }

    func preferredPrompt(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = promptYoung { return y }
        return prompt
    }
}

enum CreativityChallengeRegistry {

    static let all: [CreativityChallenge] = [
        CreativityChallenge(
            id: "cone-five-ways",
            title: "Beat the Cone 5 Ways",
            prompt: "One cone, five escapes — and no move can repeat. Different foot, different fake, different exit each time.",
            promptYoung: "Trick the cone 5 times, but every trick has to be brand new!",
            varietyTarget: 5,
            unit: "ways",
            icon: "cone.fill"
        ),
        CreativityChallenge(
            id: "juggle-body-parts",
            title: "Whole-Body Juggle",
            prompt: "Keep it up using 5 different body parts in a row — feet, thigh, chest, shoulder, head. Order is yours.",
            promptYoung: "Juggle with 5 different body parts, one after another!",
            varietyTarget: 5,
            unit: "body parts",
            icon: "figure.mixed.cardio"
        ),
        CreativityChallenge(
            id: "ten-unique-touches",
            title: "10 Touches, No Repeats",
            prompt: "Take ten touches and make every single one different — surface, direction, height, spin. Sameness loses.",
            promptYoung: "10 touches and no two the same. How weird can you get?",
            varietyTarget: 10,
            unit: "touches",
            icon: "sparkles"
        ),
        CreativityChallenge(
            id: "wall-five-surfaces",
            title: "5-Surface Wall Ball",
            prompt: "Play the wall with five different surfaces: inside, outside, laces, sole, heel. Clean return each time.",
            promptYoung: "Pass the wall 5 ways — inside, outside, laces, sole, even your heel!",
            varietyTarget: 5,
            unit: "surfaces",
            icon: "square.on.square"
        ),
        CreativityChallenge(
            id: "finish-five-angles",
            title: "Finish From 5 Angles",
            prompt: "Five finishes on goal, each from a different spot and angle. Move the ball, move yourself, repaint the picture.",
            promptYoung: "Score 5 times, but from 5 totally different places!",
            varietyTarget: 5,
            unit: "angles",
            icon: "scope"
        ),
        CreativityChallenge(
            id: "four-escapes",
            title: "4 Ways Out of Pressure",
            prompt: "Imagine pressure on your back. Escape four different ways — roll, spin, chop, or something nobody's named yet.",
            promptYoung: "A pretend defender is behind you — escape 4 different ways!",
            varietyTarget: 4,
            unit: "escapes",
            icon: "figure.run"
        ),
        CreativityChallenge(
            id: "weak-foot-moves",
            title: "Weak-Foot Remix",
            prompt: "Take 3 moves you already own and do them weak-footed. Familiar move, brand-new wiring.",
            promptYoung: "Do 3 of your favorite moves with your other foot!",
            varietyTarget: 3,
            unit: "moves",
            icon: "shoe.fill"
        ),
        CreativityChallenge(
            id: "invent-a-move",
            title: "Invent a Move",
            prompt: "Make up a move nobody taught you. Land it 3 times, then name it — it's yours forever.",
            promptYoung: "Invent your own move! Land it 3 times and give it a name!",
            varietyTarget: 3,
            unit: "landings",
            icon: "wand.and.stars",
            isInvention: true
        ),
    ]

    static func challenge(for id: String) -> CreativityChallenge? {
        all.first { $0.id == id }
    }
}

/// Chip-based move naming — two taps, zero typing, so it needs no free-text
/// permission. "Thunder Chop" beats a keyboard any day of the week.
enum MoveNameParts {
    static let first = ["Flying", "Silky", "Thunder", "Phantom", "Rocket", "Snake"]
    static let second = ["Roll", "Flick", "Spin", "Chop", "Drag", "Hop"]

    static func combined(_ a: String, _ b: String) -> String {
        "\(a) \(b)"
    }
}
