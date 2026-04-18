import Foundation
import CoreLocation
import Combine

/// Observable location-based pitch detector. When the user enters a known
/// pitch and stays inside its radius for `PitchConstants.dwellThresholdSeconds`,
/// publishes `isAtPitch = true` with the matching `TrainingPitch`. Exit
/// transitions are immediate (no dwell required).
///
/// Also surfaces new-pitch detection — when the user dwells at an unknown
/// location for the same threshold, `pendingNewLocation` is set so the
/// designation flow can prompt for a nickname + home flag.
///
/// The detector is lazy: it doesn't request permission until `start()` is
/// called from the host view. That way kids who never open the Pitch
/// banner never get a location prompt they didn't ask for.
@MainActor
final class PitchDetector: NSObject, ObservableObject {
    @Published private(set) var currentPitch: TrainingPitch?
    @Published private(set) var isAtPitch: Bool = false
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// Lat/lon of a location the user has dwelled at for >= dwell threshold
    /// but isn't a known pitch. Drives the designation flow.
    @Published var pendingNewLocation: CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()
    private let store: PitchStore
    private var currentChildId: String?
    private var dwellStartAt: Date?
    private var dwellCandidate: CLLocation?

    init(store: PitchStore = PitchStore()) {
        self.store = store
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 20  // meters — coarse enough to save battery
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Control

    /// Begin monitoring for the given child. Idempotent; safe to call on
    /// every home-view appearance. Requests permission if needed.
    func start(childId: String) {
        currentChildId = childId
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        resetDwell()
    }

    /// Create a pitch at the current dwell candidate location with the
    /// given nickname + home flag. Called by the designation flow after
    /// the parent/child confirms the new pitch is real.
    func designateCurrentDwellAsPitch(nickname: String?, isHome: Bool) async {
        guard let childId = currentChildId, let candidate = dwellCandidate else { return }
        let newPitch = await store.designatePitch(
            latitude: candidate.coordinate.latitude,
            longitude: candidate.coordinate.longitude,
            nickname: nickname,
            isHome: isHome,
            childId: childId
        )
        currentPitch = newPitch
        isAtPitch = true
        pendingNewLocation = nil
    }

    /// Dismiss the pending new-location prompt without creating a pitch
    /// (user said "not a pitch").
    func dismissPendingNew() {
        pendingNewLocation = nil
        dwellCandidate = nil
        dwellStartAt = nil
    }

    // MARK: - Private

    private func resetDwell() {
        dwellStartAt = nil
        dwellCandidate = nil
    }
}

extension PitchDetector: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways,
               let id = currentChildId {
                start(childId: id)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await evaluateLocation(location)
        }
    }

    /// Location-update core: match against known pitches, manage dwell
    /// state, and raise entry/exit transitions.
    private func evaluateLocation(_ location: CLLocation) async {
        guard let childId = currentChildId else { return }
        let nearby = await store.pitchAtLocation(location, childId: childId)

        if let pitch = nearby {
            // At a known pitch — start or continue dwell.
            if currentPitch?.id != pitch.id {
                dwellCandidate = location
                dwellStartAt = Date()
                currentPitch = pitch
                isAtPitch = false
            } else if let dwellStart = dwellStartAt,
                      Date().timeIntervalSince(dwellStart) >= PitchConstants.dwellThresholdSeconds,
                      !isAtPitch {
                // Passed dwell — count this as an arrival.
                isAtPitch = true
                await store.recordVisit(pitchId: pitch.id, childId: childId)
                dwellStartAt = nil
            }
            pendingNewLocation = nil
            return
        }

        // Not at a known pitch. If exiting a known pitch, raise the
        // transition immediately.
        if isAtPitch {
            isAtPitch = false
            currentPitch = nil
        }

        // Unknown location — start dwell counter for potential designation.
        if let dwellStart = dwellStartAt,
           let candidate = dwellCandidate,
           candidate.distance(from: location) < PitchConstants.defaultRadiusMeters {
            // Still close to the dwell candidate.
            if Date().timeIntervalSince(dwellStart) >= PitchConstants.dwellThresholdSeconds,
               pendingNewLocation == nil {
                pendingNewLocation = candidate.coordinate
            }
        } else {
            // Moved far enough to reset the dwell.
            dwellCandidate = location
            dwellStartAt = Date()
        }
    }
}
