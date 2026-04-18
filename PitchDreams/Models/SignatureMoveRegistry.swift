import Foundation

/// All signature moves known to the app. Launch ships with **3 fully-authored
/// moves** (Scissor, Body Feint, La Croqueta) — the rest appear in the
/// library as locked placeholders so the 10-tile grid stays populated,
/// and land as Month 1+ bonus drops with real content.
enum SignatureMoveRegistry {

    /// All 10 moves in display order. Fully-authored moves ship with real
    /// stage content; placeholders use `locked` stages so the UI shows them
    /// as coming-soon tiles.
    static let launchMoves: [SignatureMove] = [
        scissor,
        stepOver,
        bodyFeint,
        laCroqueta,
        elastico,
        rainbowFlick,
        rabona,
        maradonaTurn,
        zidaneRoulette,
        scorpionKick
    ]

    /// True if the move has fully-authored stage content. Placeholder moves
    /// return false — the library renders them as locked coming-soon tiles.
    static func isPlayable(_ move: SignatureMove) -> Bool {
        playableMoveIds.contains(move.id)
    }

    /// Moves whose stage content is real and drills are playable.
    /// This list grows as bonus drops ship post-launch.
    static let playableMoveIds: Set<String> = [
        "move-scissor",
        "move-body-feint",
        "move-la-croqueta"
    ]

    static func move(id: String) -> SignatureMove? {
        launchMoves.first { $0.id == id }
    }

    // MARK: - Placeholder moves

    /// Stage used for not-yet-authored moves. Shows up as locked + greyed in
    /// the library; tapping gives an informational "coming soon" state.
    static let placeholderStages: [MoveStage] = [
        MoveStage(
            order: 1, phase: .groundwork,
            name: "Coming Soon",
            description: "Full content for this move ships as a post-launch bonus drop. Check back for updates.",
            descriptionYoung: "This move is on its way! Watch for it soon.",
            drills: [],
            masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 0, requiredConfidence: 0, requiresVideoRecording: false, minTotalReps: 0)
        )
    ]

    // MARK: - Not-yet-authored placeholders

    static let stepOver = SignatureMove(
        id: "move-step-over",
        name: "Step-Over",
        rarity: .common,
        difficulty: .intermediate,
        famousFor: "Robinho's rhythm, Neymar's flair",
        description: "Circle your foot over the top of the ball without touching it, then push off with the outside of the other foot.",
        descriptionYoung: "Lift one foot up and OVER the ball — don't touch it! Then push the ball with the outside of your other foot.",
        iconSymbolName: "figure.walk.motion",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "Foot goes over the ball like stepping over a puddle!",
        coachTip: "Vertical motion over the top of the ball, not horizontal. Outside-foot push is the actual escape."
    )

    static let elastico = SignatureMove(
        id: "move-elastico",
        name: "Elastico",
        rarity: .rare,
        difficulty: .intermediate,
        famousFor: "Ronaldinho's rubber-band whip",
        description: "Push the ball outside with one foot, then snap it back inside — one fluid motion, one foot planted.",
        descriptionYoung: "Push the ball OUT with your foot, then snap it back IN! Super fast!",
        iconSymbolName: "arrow.uturn.left.circle",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "ONE foot! Push OUT, then snap IN — like a rubber band!",
        coachTip: "Single-foot execution. Outside push then inside snap-back, no foot replant between motions."
    )

    static let rainbowFlick = SignatureMove(
        id: "move-rainbow-flick",
        name: "Rainbow Flick",
        rarity: .common,
        difficulty: .beginner,
        famousFor: "Ronaldinho's crowd-pleaser",
        description: "Flick the ball up and over your head using both feet. A crowd classic.",
        descriptionYoung: "Squeeze the ball between your heels and flick it up and over your head!",
        iconSymbolName: "rainbow",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "Squeeze the ball between your heels like a sandwich!",
        coachTip: "Clamp the ball between your dominant heel and the sole of your weak foot, then flick upward."
    )

    static let rabona = SignatureMove(
        id: "move-rabona",
        name: "Rabona",
        rarity: .rare,
        difficulty: .advanced,
        famousFor: "Ronaldinho & Neymar's showstopper",
        description: "Cross your kicking leg behind your standing leg to strike the ball.",
        descriptionYoung: "Your kicking foot hides behind your other leg like peekaboo!",
        iconSymbolName: "figure.cross.training",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "Hide your kicking foot behind the other leg!",
        coachTip: "Plant strong-foot outside the ball. Swing kicking leg behind and connect with the inside."
    )

    static let maradonaTurn = SignatureMove(
        id: "move-maradona-turn",
        name: "Maradona Turn",
        rarity: .epic,
        difficulty: .advanced,
        famousFor: "Diego's 360 masterclass",
        description: "Drag the ball with one foot, spin 360°, continue with the other foot.",
        descriptionYoung: "Keep your foot on the ball and spin like a figure skater!",
        iconSymbolName: "arrow.clockwise.circle",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "Sole-drag, pivot, spin, continue!",
        coachTip: "Sole-drag, plant, 360° pivot on planting foot, continue with original foot's outside."
    )

    static let zidaneRoulette = SignatureMove(
        id: "move-zidane-roulette",
        name: "Zidane Roulette",
        rarity: .epic,
        difficulty: .advanced,
        famousFor: "Zizou's elegant 360",
        description: "Spin 360° while protecting the ball with both feet — an artistic escape from pressure.",
        descriptionYoung: "Two feet dance around the ball in a circle. You're the ball's bodyguard!",
        iconSymbolName: "arrow.triangle.2.circlepath.circle",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "Dance around the ball with both feet!",
        coachTip: "Pivot on supporting foot. Drag-drag pattern with both feet. Ball stays glued."
    )

    static let scorpionKick = SignatureMove(
        id: "move-scorpion-kick",
        name: "Scorpion Kick",
        rarity: .legendary,
        difficulty: .advanced,
        famousFor: "Higuita's impossible save, Giroud's Puskás winner",
        description: "Dive forward, kick the ball with your heels as your body flies parallel to the ground.",
        descriptionYoung: "Your heels kick the ball UP while you're flying! Only try this on grass or a mat.",
        iconSymbolName: "figure.cross.training",
        heroDemoAsset: nil,
        stages: placeholderStages,
        coachTipYoung: "Only on soft ground! Flying heel kick!",
        coachTip: "Requires strong core, hip flexibility, and a soft landing surface. Start low and slow."
    )
}
