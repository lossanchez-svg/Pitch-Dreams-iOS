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
            spaceType: "small_indoor"
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
            spaceType: "small_indoor"
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
            spaceType: "small_indoor"
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
            spaceType: "large_indoor"
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
            spaceType: "outdoor"
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
            spaceType: "outdoor"
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
            spaceType: "outdoor"
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

    static func drills(forCategory category: String) -> [DrillDefinition] {
        all.filter { $0.category == category }
    }

    static var categories: [String] {
        Array(Set(all.map(\.category))).sorted()
    }
}
