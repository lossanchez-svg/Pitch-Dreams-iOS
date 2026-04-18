import Foundation
import CoreLocation

/// Per-child persistence for known pitches. Handles designation (naming
/// + home flag), visit recording, and manual deletion.
actor PitchStore {
    private let defaults: UserDefaults
    private let mergeThresholdMeters: Double = 100  // within 100m = same pitch

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getAll(childId: String) -> [TrainingPitch] {
        guard let data = defaults.data(forKey: key(childId: childId)),
              let pitches = try? JSONDecoder().decode([TrainingPitch].self, from: data) else {
            return []
        }
        return pitches
    }

    /// The user's designated home pitch, if any.
    func homePitch(childId: String) -> TrainingPitch? {
        getAll(childId: childId).first(where: { $0.isHomePitch })
    }

    /// Create or update a pitch at the given location. If a nearby pitch
    /// already exists, merges into it (updating nickname / home flag when
    /// supplied). Marking as home clears any previous home pitch.
    @discardableResult
    func designatePitch(
        latitude: Double,
        longitude: Double,
        nickname: String?,
        isHome: Bool,
        childId: String
    ) -> TrainingPitch {
        var pitches = getAll(childId: childId)
        let newLocation = CLLocation(latitude: latitude, longitude: longitude)

        // If a nearby pitch already exists, treat this as a merge.
        if let existing = pitches.first(where: {
            $0.location.distance(from: newLocation) < mergeThresholdMeters
        }) {
            pitches = pitches.map { p in
                var updated = p
                if p.id == existing.id {
                    updated.nickname = nickname ?? p.nickname
                    if isHome { updated.isHomePitch = true }
                } else if isHome {
                    updated.isHomePitch = false
                }
                return updated
            }
            save(pitches, childId: childId)
            // The updated `existing` pitch post-mutation.
            return pitches.first(where: { $0.id == existing.id }) ?? existing
        }

        // New pitch. If setting as home, clear the flag on others.
        if isHome {
            pitches = pitches.map { p in
                var updated = p
                updated.isHomePitch = false
                return updated
            }
        }
        let now = Date()
        let newPitch = TrainingPitch(
            id: UUID().uuidString,
            nickname: nickname,
            centerLatitude: latitude,
            centerLongitude: longitude,
            radiusMeters: PitchConstants.defaultRadiusMeters,
            firstVisitedAt: now,
            lastVisitedAt: now,
            visitCount: 1,
            isHomePitch: isHome
        )
        pitches.append(newPitch)
        save(pitches, childId: childId)
        return newPitch
    }

    /// Increment visit count + lastVisitedAt on a known pitch.
    func recordVisit(pitchId: String, childId: String) {
        var pitches = getAll(childId: childId)
        pitches = pitches.map { p in
            guard p.id == pitchId else { return p }
            var updated = p
            updated.lastVisitedAt = Date()
            updated.visitCount += 1
            return updated
        }
        save(pitches, childId: childId)
    }

    /// Find the nearest pitch to a location, if any is within its own radius.
    func pitchAtLocation(_ location: CLLocation, childId: String) -> TrainingPitch? {
        let pitches = getAll(childId: childId)
        return pitches.first { pitch in
            pitch.location.distance(from: location) <= pitch.radiusMeters
        }
    }

    func deletePitch(id: String, childId: String) {
        var pitches = getAll(childId: childId)
        pitches.removeAll { $0.id == id }
        save(pitches, childId: childId)
    }

    func setHomePitch(id: String, childId: String) {
        var pitches = getAll(childId: childId)
        pitches = pitches.map { p in
            var updated = p
            updated.isHomePitch = (p.id == id)
            return updated
        }
        save(pitches, childId: childId)
    }

    /// Wipe all pitches for a child (reset-progress flow).
    func clear(childId: String) {
        defaults.removeObject(forKey: key(childId: childId))
    }

    // MARK: - Private

    private func save(_ pitches: [TrainingPitch], childId: String) {
        guard let data = try? JSONEncoder().encode(pitches) else { return }
        defaults.set(data, forKey: key(childId: childId))
    }

    private func key(childId: String) -> String { "training_pitches_\(childId)" }
}
