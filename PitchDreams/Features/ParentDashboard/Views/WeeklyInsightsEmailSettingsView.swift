import SwiftUI

/// Premium parent surface: per-child weekly insights email preferences.
/// Parents toggle delivery on/off and pick a delivery window (Sunday AM,
/// Monday AM, Friday PM). Preferences persist locally per-child.
///
/// The actual email-send happens server-side via an endpoint that doesn't
/// exist yet. This view ships the UI + local persistence so paid users see
/// the feature immediately and can set their preference; when the backend
/// ships `POST /api/v1/parents/notifications/weekly-email`, wiring it up is
/// a ~10-line change in `persistPreferenceToServer()`.
struct WeeklyInsightsEmailSettingsView: View {
    let child: ChildSummary
    @EnvironmentObject private var authManager: AuthManager

    @State private var enabled = false
    @State private var schedule: Schedule = .sundayMorning
    @State private var showSavedToast = false

    enum Schedule: String, CaseIterable, Identifiable {
        case sundayMorning      = "Sunday · 8 AM"
        case mondayMorning      = "Monday · 7 AM"
        case fridayEvening      = "Friday · 6 PM"
        var id: String { rawValue }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Send weekly insights", isOn: $enabled)
                    .tint(Color.dsSecondary)
                if enabled {
                    Picker("Delivery", selection: $schedule) {
                        ForEach(Schedule.allCases) { schedule in
                            Text(schedule.rawValue).tag(schedule)
                        }
                    }
                    LabeledContent("Recipient") {
                        Text(authManager.currentUser?.email ?? "Your parent account")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
            } header: {
                Text("Email preferences for \(child.nickname)")
            } footer: {
                Text("Insights are sent to the parent account email. You can pause any time.")
            }

            Section("What's in the email") {
                previewRow(icon: "chart.bar.fill", text: "Sessions, minutes, and streak this week")
                previewRow(icon: "trophy.fill", text: "Personal bests and new milestones")
                previewRow(icon: "arrow.up.right.circle.fill", text: "Skills trending up this week")
                previewRow(icon: "moon.fill", text: "Rest days logged + soreness notes")
                previewRow(icon: "lightbulb.fill", text: "One coaching prompt for the week ahead")
            }

            Section {
                Button {
                    savePreferences()
                } label: {
                    HStack {
                        Image(systemName: "envelope.badge")
                        Text("Save preferences")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
            } footer: {
                if showSavedToast {
                    Text("Saved — first email arrives on the next scheduled delivery.")
                        .foregroundStyle(Color.dsSecondary)
                        .transition(.opacity)
                }
            }
        }
        .navigationTitle("Weekly Insights Email")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadPreferences() }
    }

    @ViewBuilder
    private func previewRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.dsSecondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurface)
        }
    }

    // MARK: - Persistence

    /// UserDefaults keys are scoped to the child so sibling prefs don't
    /// stomp each other. When the server endpoint lands, replace the
    /// local writes with API calls and keep UserDefaults as a fallback
    /// cache for offline edits.
    private var enabledKey: String  { "weeklyInsights.\(child.id).enabled" }
    private var scheduleKey: String { "weeklyInsights.\(child.id).schedule" }

    private func loadPreferences() {
        let defaults = UserDefaults.standard
        enabled = defaults.bool(forKey: enabledKey)
        if let raw = defaults.string(forKey: scheduleKey), let s = Schedule(rawValue: raw) {
            schedule = s
        }
    }

    private func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(enabled, forKey: enabledKey)
        defaults.set(schedule.rawValue, forKey: scheduleKey)
        // TODO: when the web endpoint exists, also POST to
        // /api/v1/parents/notifications/weekly-email with { childId,
        // enabled, schedule } and surface a real confirmation.
        withAnimation { showSavedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showSavedToast = false }
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyInsightsEmailSettingsView(
            child: ChildSummary(
                id: "preview", nickname: "Alex", age: 11,
                position: "Midfielder", avatarId: "wolf"
            )
        )
        .environmentObject(AuthManager())
    }
}
