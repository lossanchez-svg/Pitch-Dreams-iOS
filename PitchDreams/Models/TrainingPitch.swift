import Foundation
import CoreLocation

/// A real-world soccer pitch the child has trained at. Created either by
/// GPS-based detection (first visit → designation flow) or by manual add.
///
/// The `radiusMeters` is the "you are here" tolerance used by
/// `PitchDetector` when deciding whether the current location counts as
/// "at this pitch." Default 75m covers a standard youth field.
struct TrainingPitch: Codable, Identifiable, Equatable {
    let id: String
    var nickname: String?
    let centerLatitude: Double
    let centerLongitude: Double
    var radiusMeters: Double
    let firstVisitedAt: Date
    var lastVisitedAt: Date
    var visitCount: Int
    var isHomePitch: Bool

    var location: CLLocation {
        CLLocation(latitude: centerLatitude, longitude: centerLongitude)
    }

    /// Fallback display name when a nickname isn't set.
    var displayName: String {
        if let nickname, !nickname.isEmpty { return nickname }
        return "Unnamed Pitch"
    }
}

/// Default pitch detection radius — a standard youth field corner-to-corner
/// covers ~70-80m, so 75 lands the user as "at pitch" across the whole
/// playing area including the sideline.
enum PitchConstants {
    static let defaultRadiusMeters: Double = 75
    /// Minimum seconds a user must dwell within radius before we declare
    /// them "at pitch." Avoids flapping if they drive past.
    static let dwellThresholdSeconds: TimeInterval = 60
    /// XP multiplier applied while at a pitch.
    static let atPitchMultiplier: Double = 2.0
}
