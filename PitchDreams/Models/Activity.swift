import Foundation

enum ActivityType: String, Codable, CaseIterable {
    case selfTraining = "SELF_TRAINING"
    case coach1on1 = "COACH_1ON1"
    case teamTraining = "TEAM_TRAINING"
    case facilityClass = "FACILITY_CLASS"
    case officialGame = "OFFICIAL_GAME"
    case futsalGame = "FUTSAL_GAME"
    case indoorLeagueGame = "INDOOR_LEAGUE_GAME"

    var displayName: String {
        switch self {
        case .selfTraining: return "Self Training"
        case .coach1on1: return "1-on-1 Coaching"
        case .teamTraining: return "Team Training"
        case .facilityClass: return "Facility Class"
        case .officialGame: return "Official Game"
        case .futsalGame: return "Futsal Game"
        case .indoorLeagueGame: return "Indoor League"
        }
    }
}

enum GameIQImpact: String, Codable, CaseIterable { case low = "LOW", medium = "MEDIUM", high = "HIGH" }

struct ActivityItem: Codable, Identifiable {
    let id: String
    let childId: String
    let activityType: String
    let durationMinutes: Int
    let intensityRPE: Int?
    let gameIQImpact: String?
    let createdAt: String
}

/// Response from POST /children/{id}/activities — returns `activityId` not full ActivityItem
struct ActivityCreateResult: Codable {
    let activityId: String
}
