import Foundation

// MARK: - Skill Animation Key

enum SkillAnimationKey: String, CaseIterable {
    case juggling
    case dribbling
    case passing
    case shooting
    case firstTouch = "first_touch"
    case defending
    case scanning
    case decision
    case tempo
    case generic
}

// MARK: - Speed Line Direction

enum SpeedLineDirection: Equatable {
    case left
    case right
    case up
    case radial
}

// MARK: - Skill Animation Config

struct SkillAnimationConfig {
    let displayName: String
    let description: String
    let durationSeconds: TimeInterval
    let showsBall: Bool
    let hasImpactFlash: Bool
    let speedLineDirection: SpeedLineDirection
}

// MARK: - Config Registry

enum SkillAnimationRegistry {

    static let configs: [SkillAnimationKey: SkillAnimationConfig] = [
        .juggling: SkillAnimationConfig(
            displayName: "Ball Control",
            description: "Juggling the ball with skill and precision",
            durationSeconds: 2.0,
            showsBall: true,
            hasImpactFlash: false,
            speedLineDirection: .up
        ),
        .dribbling: SkillAnimationConfig(
            displayName: "Speed Burst",
            description: "Explosive dribbling with the ball",
            durationSeconds: 1.8,
            showsBall: true,
            hasImpactFlash: false,
            speedLineDirection: .right
        ),
        .passing: SkillAnimationConfig(
            displayName: "Perfect Pass",
            description: "Precise ball delivery to teammate",
            durationSeconds: 1.5,
            showsBall: true,
            hasImpactFlash: true,
            speedLineDirection: .right
        ),
        .shooting: SkillAnimationConfig(
            displayName: "Power Shot",
            description: "Powerful strike on goal",
            durationSeconds: 2.0,
            showsBall: true,
            hasImpactFlash: true,
            speedLineDirection: .right
        ),
        .firstTouch: SkillAnimationConfig(
            displayName: "Silky Touch",
            description: "Perfect ball control on first contact",
            durationSeconds: 1.6,
            showsBall: true,
            hasImpactFlash: false,
            speedLineDirection: .left
        ),
        .defending: SkillAnimationConfig(
            displayName: "Ball Won",
            description: "Strong defensive play",
            durationSeconds: 1.4,
            showsBall: true,
            hasImpactFlash: true,
            speedLineDirection: .left
        ),
        .scanning: SkillAnimationConfig(
            displayName: "Field Vision",
            description: "Scanning the field for opportunities",
            durationSeconds: 1.8,
            showsBall: false,
            hasImpactFlash: false,
            speedLineDirection: .radial
        ),
        .decision: SkillAnimationConfig(
            displayName: "Quick Decision",
            description: "Making the right choice under pressure",
            durationSeconds: 1.6,
            showsBall: false,
            hasImpactFlash: false,
            speedLineDirection: .radial
        ),
        .tempo: SkillAnimationConfig(
            displayName: "Game Control",
            description: "Controlling the pace of play",
            durationSeconds: 1.8,
            showsBall: true,
            hasImpactFlash: false,
            speedLineDirection: .right
        ),
        .generic: SkillAnimationConfig(
            displayName: "Training Complete",
            description: "Another successful training session",
            durationSeconds: 1.5,
            showsBall: true,
            hasImpactFlash: false,
            speedLineDirection: .up
        ),
    ]

    /// Resolve an animation key from a drill key string (e.g. "scanning.3point_scan" → .scanning)
    static func resolve(_ drillKey: String) -> SkillAnimationKey {
        // Direct match
        if let key = SkillAnimationKey(rawValue: drillKey) {
            return key
        }
        // Match by track prefix (e.g. "scanning.3point_scan" → "scanning")
        let prefix = drillKey.components(separatedBy: ".").first ?? ""
        if let key = SkillAnimationKey(rawValue: prefix) {
            return key
        }
        // Known mappings
        let mappings: [String: SkillAnimationKey] = [
            "ball_mastery": .dribbling,
            "receiving": .firstTouch,
            "tackling": .defending,
            "first_touch": .firstTouch,
        ]
        if let key = mappings[drillKey] {
            return key
        }
        return .generic
    }

    /// Get the config for a given key. Falls back to .generic if somehow missing.
    static func config(for key: SkillAnimationKey) -> SkillAnimationConfig {
        configs[key] ?? configs[.generic]!
    }
}
