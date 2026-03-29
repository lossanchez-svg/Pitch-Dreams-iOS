import Foundation

struct WeeklyTrend: Codable {
    let sessionsCount: Int
    let avgQualityRating: Double?
    let completionRate: Double
    let hasPBMovement: Bool
    let isLowEngagement: Bool
    let weeksLowEngagement: Int
}
