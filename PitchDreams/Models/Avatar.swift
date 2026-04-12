import Foundation

/// One of the eight avatar identities a child can pick during onboarding.
/// Raw value matches the `avatarId` string persisted on the server.
enum Avatar: String, CaseIterable, Identifiable {
    case wolf
    case lion
    case eagle
    case fox
    case shark
    case panther
    case bear
    case `default`

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wolf: return "Wolf"
        case .lion: return "Lion"
        case .eagle: return "Eagle"
        case .fox: return "Fox"
        case .shark: return "Shark"
        case .panther: return "Panther"
        case .bear: return "Bear"
        case .default: return "Player"
        }
    }

    /// Asset catalog name for the given evolution stage.
    func assetName(stage: AvatarStage) -> String {
        "\(rawValue)_stage\(stage.rawValue)"
    }
}

/// Three evolution stages every avatar moves through as the child practices.
enum AvatarStage: Int, CaseIterable, Comparable {
    case rookie = 1
    case pro = 2
    case legend = 3

    var title: String {
        switch self {
        case .rookie: return "Rookie"
        case .pro: return "Pro"
        case .legend: return "Legend"
        }
    }

    /// Threshold (in days of streak milestones reached) required to unlock this stage.
    var unlockMilestone: Int {
        switch self {
        case .rookie: return 0
        case .pro: return 7
        case .legend: return 30
        }
    }

    /// Derive the highest unlocked stage from the streak milestones the child has reached,
    /// optionally boosted by locally-earned mission XP. Missions provide a parallel path
    /// to evolution: 50 XP → Pro, 200 XP → Legend. The returned stage is the max of the
    /// streak-based stage and the XP-based stage.
    /// Streak milestones are server-tracked day counts (e.g. 7, 14, 30).
    static func current(forMilestones milestones: [Int], localMissionXP: Int = 0) -> AvatarStage {
        let best = milestones.max() ?? 0
        var stage: AvatarStage = .rookie
        if best >= AvatarStage.legend.unlockMilestone { stage = .legend }
        else if best >= AvatarStage.pro.unlockMilestone { stage = .pro }

        var xpStage: AvatarStage = .rookie
        if localMissionXP >= 200 { xpStage = .legend }
        else if localMissionXP >= 50 { xpStage = .pro }

        return max(stage, xpStage)
    }

    static func < (lhs: AvatarStage, rhs: AvatarStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Avatar {
    /// Legacy avatarId strings from the previous human-art system, mapped onto
    /// the closest match in the new anthropomorphic-animal lineup. Existing accounts
    /// keep working without a server migration.
    private static let legacyMigrations: [String: Avatar] = [
        "defender_girl_01": .panther,
        "midfield_boy_01": .wolf,
        "midfield_boy_02": .lion,
        "winger_boy_01": .fox
    ]

    /// Resolve an Avatar from a stored avatarId, accepting both current ids
    /// (`wolf`, `lion`, …) and legacy ids from the old asset system.
    /// Falls back to `.default` if nothing matches.
    static func resolve(_ avatarId: String?) -> Avatar {
        guard let id = avatarId else { return .default }
        if let direct = Avatar(rawValue: id) { return direct }
        if let migrated = legacyMigrations[id] { return migrated }
        return .default
    }

    /// Resolve the right asset name from a stored avatarId string + the child's milestones.
    static func assetName(for avatarId: String?, milestones: [Int], localMissionXP: Int = 0) -> String {
        let avatar = resolve(avatarId)
        let stage = AvatarStage.current(forMilestones: milestones, localMissionXP: localMissionXP)
        return avatar.assetName(stage: stage)
    }
}
