import SwiftUI
import UserNotifications

/// Parent-facing screen to enable and schedule a child's daily training
/// reminder. The time picker is clamped to 07:00–21:00 so we never schedule
/// during quiet hours.
struct NotificationSettingsView: View {
    let childId: String
    let childName: String

    @State private var enabled: Bool = false
    @State private var reminderTime: Date = Self.defaultTime
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var didAttemptAuthRequest = false
    @State private var showSettingsPrompt = false

    private static var defaultTime: Date {
        var components = DateComponents()
        components.hour = 16
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        Form {
            Section {
                Toggle("Daily Training Reminder", isOn: $enabled)
                    .onChange(of: enabled) { newValue in
                        Task { await applyChanges(enabledOverride: newValue) }
                    }

                if enabled {
                    DatePicker(
                        "Reminder time",
                        selection: $reminderTime,
                        in: allowedTimeRange,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: reminderTime) { _ in
                        Task { await applyChanges() }
                    }
                }
            } header: {
                Text("Training Reminder")
            } footer: {
                Text("Sends \(childName) a daily nudge at the chosen time. Messages adapt to their current streak. Quiet hours (9 pm – 7 am) are respected automatically.")
            }

            if authorizationStatus == .denied {
                Section {
                    Button {
                        openAppSettings()
                    } label: {
                        Label("Open System Settings", systemImage: "gear")
                    }
                } footer: {
                    Text("Notifications are turned off for PitchDreams. Enable them in iOS Settings so reminders can be sent.")
                        .foregroundStyle(.orange)
                }
            }

            if enabled && authorizationStatus != .denied {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Test reminder: \(previewText)")
                            .font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInitialState()
        }
    }

    // MARK: - Derived

    private var allowedTimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .hour, value: 7, to: today) ?? today
        let end = calendar.date(byAdding: .hour, value: 21, to: today) ?? today
        return start...end
    }

    private var previewText: String {
        let content = TrainingReminderManager.makeContent(nickname: childName, streak: 0)
        return "\"\(content.title)\" — adapts to streak"
    }

    // MARK: - Actions

    private func loadInitialState() async {
        let prefs = TrainingReminderManager.prefs(childId: childId)
        enabled = prefs.enabled
        var comps = DateComponents()
        comps.hour = prefs.hour
        comps.minute = prefs.minute
        if let date = Calendar.current.date(from: comps) {
            reminderTime = date
        }
        authorizationStatus = await TrainingReminderManager.authorizationStatus()
    }

    private func applyChanges(enabledOverride: Bool? = nil) async {
        let wantsEnabled = enabledOverride ?? enabled
        if wantsEnabled && !didAttemptAuthRequest {
            didAttemptAuthRequest = true
            _ = await TrainingReminderManager.requestAuthorizationIfNeeded()
            authorizationStatus = await TrainingReminderManager.authorizationStatus()
            if authorizationStatus == .denied {
                enabled = false
                TrainingReminderManager.savePrefs(
                    TrainingReminderManager.Prefs(enabled: false, hour: components(of: reminderTime).hour, minute: components(of: reminderTime).minute),
                    childId: childId
                )
                TrainingReminderManager.cancelReminder(childId: childId)
                return
            }
        }

        let (hour, minute) = components(of: reminderTime)
        let prefs = TrainingReminderManager.Prefs(enabled: wantsEnabled, hour: hour, minute: minute)
        TrainingReminderManager.savePrefs(prefs, childId: childId)
        await TrainingReminderManager.scheduleDailyReminder(
            childId: childId,
            childNickname: childName,
            streak: 0  // Real streak gets refreshed from ChildHomeView when the app opens.
        )
    }

    private func components(of date: Date) -> (hour: Int, minute: Int) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 16, c.minute ?? 30)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(childId: "preview", childName: "Jude")
    }
}
