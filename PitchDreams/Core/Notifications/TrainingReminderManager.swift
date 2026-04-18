import Foundation
import UserNotifications

/// Schedules the single most effective retention lever: a daily training
/// reminder at a user-chosen time. Content varies with the current streak
/// state at the moment we (re)schedule, so the notification text feels alive.
///
/// Per-child preferences (enabled / hour / minute) are stored in UserDefaults.
/// Each child gets its own notification identifier so multiple kids on one
/// device each get their own nudge — typically at different times.
///
/// Quiet hours: the `NotificationSettingsView` clamps the allowed range to
/// 07:00–21:00. Out-of-range values are rejected at the view layer.
@MainActor
enum TrainingReminderManager {

    // MARK: - Prefs

    struct Prefs: Equatable {
        var enabled: Bool
        var hour: Int
        var minute: Int

        static let defaultPrefs = Prefs(enabled: false, hour: 16, minute: 30)

        /// Clamp to 07:00–21:00 window. Anything outside is coerced in so
        /// we never schedule during quiet hours even if bad input slips in.
        var clamped: Prefs {
            var h = hour
            var m = minute
            if h < 7 { h = 7; m = 0 }
            if h > 21 { h = 21; m = 0 }
            if h == 21 && m > 0 { m = 0 }
            return Prefs(enabled: enabled, hour: h, minute: m)
        }
    }

    // MARK: - Prefs storage

    static func prefs(childId: String) -> Prefs {
        let defaults = UserDefaults.standard
        let key = prefsKey(childId: childId)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(StoredPrefs.self, from: data) else {
            return .defaultPrefs
        }
        return Prefs(enabled: decoded.enabled, hour: decoded.hour, minute: decoded.minute)
    }

    static func savePrefs(_ prefs: Prefs, childId: String) {
        let clamped = prefs.clamped
        let stored = StoredPrefs(enabled: clamped.enabled, hour: clamped.hour, minute: clamped.minute)
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: prefsKey(childId: childId))
        }
    }

    // MARK: - Authorization

    /// Request permission if status is .notDetermined. Returns whether
    /// we are now allowed to post notifications.
    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedule (or reschedule) the daily reminder for a child using the
    /// current prefs. Content is tailored to `streak`. No-op if prefs.enabled
    /// is false — in that case we also cancel any existing schedule so the
    /// disable toggle actually disables.
    static func scheduleDailyReminder(childId: String, childNickname: String?, streak: Int) async {
        let prefs = prefs(childId: childId).clamped
        guard prefs.enabled else {
            cancelReminder(childId: childId)
            return
        }
        guard await requestAuthorizationIfNeeded() else {
            // Permission was denied; don't attempt to schedule.
            return
        }

        let content = makeContent(nickname: childNickname, streak: streak)

        var components = DateComponents()
        components.hour = prefs.hour
        components.minute = prefs.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier(childId: childId),
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        // Remove any prior-scheduled version before adding, so content updates
        // with the latest streak value instead of piling up.
        center.removePendingNotificationRequests(withIdentifiers: [identifier(childId: childId)])
        try? await center.add(request)
    }

    /// Cancel the reminder for a single child.
    static func cancelReminder(childId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier(childId: childId)])
    }

    // MARK: - Private

    private struct StoredPrefs: Codable {
        var enabled: Bool
        var hour: Int
        var minute: Int
    }

    private static func identifier(childId: String) -> String {
        "training_reminder_\(childId)"
    }

    private static func prefsKey(childId: String) -> String {
        "training_reminder_prefs_\(childId)"
    }

    /// Build a streak-adaptive notification body. The title is always upbeat;
    /// the body carries the specifics.
    static func makeContent(nickname: String?, streak: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let name = nickname?.isEmpty == false ? nickname! : "Player"
        if streak >= 30 {
            content.title = "\(streak) days strong, \(name)."
            content.body = "Legend moves don't take days off."
        } else if streak >= 7 {
            content.title = "Your \(streak)-day streak is waiting."
            content.body = "Don't let the streak break. Quick session?"
        } else if streak >= 1 {
            content.title = "Keep the streak alive."
            content.body = "\(streak) day\(streak == 1 ? "" : "s") in. Today makes it \(streak + 1)."
        } else {
            content.title = "Time to train."
            content.body = "Start a new streak today. Takes 5 minutes."
        }
        content.sound = .default
        return content
    }
}
