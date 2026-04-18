import Foundation
import StoreKit
import UIKit

/// Requests a system review prompt at high-signal moments.
///
/// Apple caps the system prompt at 3/year automatically — we can call
/// `requestReview()` liberally at genuinely positive moments and iOS will
/// decide when (or whether) to show it.
///
/// Triggers wired into the app:
///   • 5th completed training session (first-time)
///   • Every streak milestone (7 / 14 / 30 / 100 days)
///   • Avatar evolution (Rookie → Pro, Pro → Legend)
///
/// We never prompt during an error, interruption, or mid-drill — only on
/// success screens the user is already savoring.
@MainActor
enum ReviewPromptManager {

    private static let defaults = UserDefaults.standard
    private static let totalSessionsKey = "review_totalSessionsCounted"
    private static let lastPromptDateKey = "review_lastPromptDate"
    private static let milestonesPromptedKey = "review_milestonesPrompted"

    /// Call after a training session successfully saves.
    /// Prompts on the 5th session (once).
    static func noteSessionCompleted() {
        let count = defaults.integer(forKey: totalSessionsKey) + 1
        defaults.set(count, forKey: totalSessionsKey)
        if count == 5 {
            requestReview(reason: "fifth_session")
        }
    }

    /// Call when a streak milestone modal is celebrated.
    /// Prompts once per milestone (never re-prompts for the same number).
    static func noteStreakMilestone(_ milestone: Int) {
        guard [7, 14, 30, 100].contains(milestone) else { return }
        var prompted = Set(defaults.array(forKey: milestonesPromptedKey) as? [Int] ?? [])
        guard !prompted.contains(milestone) else { return }
        prompted.insert(milestone)
        defaults.set(Array(prompted), forKey: milestonesPromptedKey)
        requestReview(reason: "streak_\(milestone)")
    }

    /// Call when the avatar evolves (handled inside EvolutionModal).
    static func noteAvatarEvolution(to stage: AvatarStage) {
        requestReview(reason: "evolution_\(stage.rawValue)")
    }

    // MARK: - Private

    /// Fires `SKStoreReviewController.requestReview` on the current scene,
    /// respecting a conservative 90-day local floor on top of Apple's own 3/year cap.
    private static func requestReview(reason: String) {
        let now = Date()
        if let last = defaults.object(forKey: lastPromptDateKey) as? Date,
           now.timeIntervalSince(last) < 60 * 60 * 24 * 90 {
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: scene)
        defaults.set(now, forKey: lastPromptDateKey)
    }
}
