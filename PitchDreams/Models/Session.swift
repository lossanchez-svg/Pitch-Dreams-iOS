import Foundation

struct SessionLog: Codable, Identifiable {
    let id: String
    let childId: String
    let activityType: String?
    let effortLevel: Int?
    let mood: String?
    let duration: Int?
    let win: String?
    let focus: String?
    let createdAt: String
}

enum SessionMode: String, Codable { case peak = "PEAK", normal = "NORMAL", lowBattery = "LOW_BATTERY", recovery = "RECOVERY" }
enum Soreness: String, Codable, CaseIterable { case none = "NONE", light = "LIGHT", medium = "MEDIUM", high = "HIGH" }
enum MoodEmoji: String, Codable, CaseIterable { case excited = "EXCITED", focused = "FOCUSED", okay = "OKAY", tired = "TIRED", stressed = "STRESSED" }

struct CheckIn: Codable, Identifiable {
    let id: String
    let childId: String
    let energy: Int
    let soreness: String
    let focus: Int
    let mood: String
    let timeAvail: Int
    let painFlag: Bool
    let mode: String
    let modeExplanation: String?
    let qualityRating: Int?
    let completed: Bool
    let activityId: String?
    let createdAt: String
}

struct SessionModeResult: Codable {
    let mode: String
    let explanation: String
}

struct CheckInResponse: Codable {
    let checkIn: CheckIn
    let modeResult: SessionModeResult
}
