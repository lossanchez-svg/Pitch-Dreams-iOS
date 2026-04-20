import Foundation

struct DrillDefinition: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let duration: Int  // seconds
    let reps: Int
    let coachTip: String
    let difficulty: String  // beginner, intermediate, advanced
    let spaceType: String   // small_indoor, large_indoor, outdoor
    /// When true, this drill is only surfaced to accounts with the
    /// `.advancedDrills` feature entitlement. Reserved for difficulty
    /// == "advanced" entries; beginner/intermediate stay free under Model 1.
    var requiresPremium: Bool = false
    /// Asset id matching an entry in `TechniqueAnimationRegistry`.
    /// When non-nil, `ActiveDrillView` renders the authored keyframe
    /// animation above the timer ring.
    var diagramAnimationAsset: String? = nil
}

enum DrillRegistry {
    static let all: [DrillDefinition] = [
        // Ball Mastery
        DrillDefinition(
            id: "bm-toe-taps",
            name: "Toe Taps",
            category: "Ball Mastery",
            description: "Alternate tapping the top of the ball with each foot as quickly as you can while staying balanced.",
            duration: 60,
            reps: 50,
            coachTip: "Keep your eyes up, not on the ball. Light touches only.",
            difficulty: "beginner",
            spaceType: "small_indoor",
            diagramAnimationAsset: "diagram_toe_taps"
        ),
        DrillDefinition(
            id: "bm-sole-rolls",
            name: "Sole Rolls",
            category: "Ball Mastery",
            description: "Roll the ball side to side under the sole of one foot, then switch. Focus on smooth, controlled movements.",
            duration: 60,
            reps: 30,
            coachTip: "Stay on the balls of your feet. Keep your body low and centered.",
            difficulty: "beginner",
            spaceType: "small_indoor",
            diagramAnimationAsset: "diagram_sole_rolls"
        ),
        DrillDefinition(
            id: "bm-foundation",
            name: "Foundation Touches",
            category: "Ball Mastery",
            description: "Inside-outside-sole sequence on each foot. Build rhythm before adding speed.",
            duration: 90,
            reps: 20,
            coachTip: "Master the pattern slowly first. Speed comes from confidence.",
            difficulty: "intermediate",
            spaceType: "small_indoor",
            diagramAnimationAsset: "diagram_foundation_touches"
        ),

        // Passing
        DrillDefinition(
            id: "pass-wall",
            name: "Wall Passes",
            category: "Passing",
            description: "Pass the ball firmly against a wall and control the return. Alternate feet.",
            duration: 120,
            reps: 40,
            coachTip: "Lock your ankle and follow through. Cushion the return with a soft touch.",
            difficulty: "beginner",
            spaceType: "large_indoor",
            diagramAnimationAsset: "diagram_wall_passes"
        ),
        DrillDefinition(
            id: "pass-triangle",
            name: "Triangle Passing",
            category: "Passing",
            description: "Set up 3 cones in a triangle. Pass to each cone, run to receive. Work on first touch direction.",
            duration: 120,
            reps: 20,
            coachTip: "Open your body to the next target before the ball arrives.",
            difficulty: "intermediate",
            spaceType: "outdoor",
            diagramAnimationAsset: "diagram_triangle_passing"
        ),

        // Shooting
        DrillDefinition(
            id: "shoot-placement",
            name: "Target Shooting",
            category: "Shooting",
            description: "Place targets in the corners of the goal. Focus on accuracy over power from the edge of the box.",
            duration: 180,
            reps: 15,
            coachTip: "Plant foot beside the ball pointing at the target. Head over the ball.",
            difficulty: "intermediate",
            spaceType: "outdoor"
        ),
        DrillDefinition(
            id: "shoot-volleys",
            name: "Drop Volleys",
            category: "Shooting",
            description: "Drop the ball from your hands and volley it at the goal. Focus on timing and clean contact.",
            duration: 120,
            reps: 10,
            coachTip: "Watch the ball all the way onto your foot. Lock your ankle.",
            difficulty: "advanced",
            spaceType: "outdoor",
            requiresPremium: true
        ),
        DrillDefinition(
            id: "shoot-weak-foot",
            name: "Weak Foot Finishing",
            category: "Shooting",
            description: "10 placed finishes with your weaker foot from the edge of the box. Equal reps each corner. No excuses.",
            duration: 180,
            reps: 10,
            coachTip: "Plant foot beside the ball, eyes on the target, follow through across your body.",
            difficulty: "advanced",
            spaceType: "outdoor",
            requiresPremium: true
        ),

        // Dribbling
        DrillDefinition(
            id: "drib-cones",
            name: "Cone Weave",
            category: "Dribbling",
            description: "Set up 6 cones in a line. Dribble through using both feet, inside and outside touches.",
            duration: 90,
            reps: 10,
            coachTip: "Close control between cones, then explode out of the last one.",
            difficulty: "beginner",
            spaceType: "outdoor",
            diagramAnimationAsset: "diagram_cone_weave"
        ),
        DrillDefinition(
            id: "drib-1v1-moves",
            name: "1v1 Moves",
            category: "Dribbling",
            description: "Practice stepover, scissors, and Cruyff turn against a cone defender. Sell the fake.",
            duration: 120,
            reps: 15,
            coachTip: "Drop your shoulder and shift your weight to sell the move.",
            difficulty: "intermediate",
            spaceType: "large_indoor"
        ),
        DrillDefinition(
            id: "drib-1v1-combo",
            name: "Combo Moves",
            category: "Dribbling",
            description: "Chain two moves — scissor into cut, stepover into La Croqueta — against a cone. Sell the first, explode off the second.",
            duration: 150,
            reps: 12,
            coachTip: "The second move only works if the first was believed. Commit to the fake.",
            difficulty: "advanced",
            spaceType: "large_indoor",
            requiresPremium: true
        ),
        DrillDefinition(
            id: "drib-speed-corridor",
            name: "Speed Dribble Corridor",
            category: "Dribbling",
            description: "Two parallel cone lines 1.5m apart, 15m long. Dribble through at top speed without touching a cone. Alternate feet each touch.",
            duration: 120,
            reps: 8,
            coachTip: "Eyes up as much as possible. Close touches under pressure beat long touches at jog pace.",
            difficulty: "advanced",
            spaceType: "outdoor",
            requiresPremium: true
        ),

        // First Touch
        DrillDefinition(
            id: "ft-juggling",
            name: "Juggling Challenge",
            category: "First Touch",
            description: "Keep the ball in the air using feet, thighs, and head. Track your record and try to beat it.",
            duration: 120,
            reps: 1,
            coachTip: "Relax your ankle on contact. Small, controlled touches upward.",
            difficulty: "beginner",
            spaceType: "small_indoor"
        ),
    ]

    static func drills(for spaceType: String) -> [DrillDefinition] {
        all.filter { $0.spaceType == spaceType }
    }

    /// Drills for a given space that the caller is entitled to. When
    /// `hasPremium` is false, advanced/premium-gated drills are filtered
    /// out — kids on the free tier simply don't see them in the active
    /// training flow, honoring the "no paywall mid-training" rule.
    static func drills(for spaceType: String, hasPremium: Bool) -> [DrillDefinition] {
        let byspace = drills(for: spaceType)
        return hasPremium ? byspace : byspace.filter { !$0.requiresPremium }
    }

    /// Premium-gated drills for a given space. Used by the space-selection
    /// "N more with Premium" footer to tease the locked catalog to parents
    /// without exposing it in the kid's drill rotation.
    static func premiumDrills(for spaceType: String) -> [DrillDefinition] {
        drills(for: spaceType).filter { $0.requiresPremium }
    }

    static func drills(forCategory category: String) -> [DrillDefinition] {
        all.filter { $0.category == category }
    }

    static var categories: [String] {
        Array(Set(all.map(\.category))).sorted()
    }
}
