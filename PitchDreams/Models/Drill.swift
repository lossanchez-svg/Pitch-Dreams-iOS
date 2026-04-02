import Foundation

struct DrillStat: Codable, Identifiable {
    var id: String { drillId }
    let drillId: String
    let drillKey: String
    let totalAttempts: Int
    let avgConfidence: Double
    let lastAttempt: String?
}

struct LogDrillResult: Codable {
    let logId: String
}

struct SessionSaveResult: Codable {
    let sessionId: String
}
