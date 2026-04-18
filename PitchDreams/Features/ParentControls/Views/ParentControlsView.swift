import SwiftUI

enum CoachPersonality: String, CaseIterable, Identifiable {
    case manager = "manager"
    case hype = "hype"
    case zen = "zen"
    case drill = "drill"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manager: return "Manager"
        case .hype: return "Hype Coach"
        case .zen: return "Zen Coach"
        case .drill: return "Drill Sergeant"
        }
    }

    var description: String {
        switch self {
        case .manager: return "Balanced and professional"
        case .hype: return "Energetic and encouraging"
        case .zen: return "Calm and mindful"
        case .drill: return "Tough love with humor"
        }
    }

    var icon: String {
        switch self {
        case .manager: return "briefcase.fill"
        case .hype: return "flame.fill"
        case .zen: return "leaf.fill"
        case .drill: return "figure.strengthtraining.traditional"
        }
    }

    /// Asset catalog image name for this coach personality.
    var imageName: String {
        "coach_\(rawValue)"
    }

    /// Coach character name shown alongside tips and nudges.
    var coachName: String {
        switch self {
        case .manager: return "Coach Kai"
        case .hype: return "Coach Blaze"
        case .zen: return "Coach Sage"
        case .drill: return "Coach Steel"
        }
    }

    // MARK: - UserDefaults Persistence

    private static let defaultsKeyPrefix = "coachPersonality_"

    /// The currently selected coach personality for the active child, persisted in UserDefaults.
    /// Falls back to a global key if no child-specific key is set.
    static var current: CoachPersonality {
        // Try active child's key first
        if let childId = UserDefaults.standard.string(forKey: "activeChildId"),
           let raw = UserDefaults.standard.string(forKey: defaultsKeyPrefix + childId),
           let personality = CoachPersonality(rawValue: raw) {
            return personality
        }
        // Fall back to global key (legacy)
        if let raw = UserDefaults.standard.string(forKey: "coachPersonality"),
           let personality = CoachPersonality(rawValue: raw) {
            return personality
        }
        return .manager
    }

    /// Save this personality for a specific child.
    func save(forChildId childId: String) {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKeyPrefix + childId)
        UserDefaults.standard.set(childId, forKey: "activeChildId")
        // Also write global key for views that don't have a childId
        UserDefaults.standard.set(rawValue, forKey: "coachPersonality")
    }

    /// Load the saved personality for a specific child.
    static func saved(forChildId childId: String) -> CoachPersonality {
        guard let raw = UserDefaults.standard.string(forKey: defaultsKeyPrefix + childId),
              let personality = CoachPersonality(rawValue: raw) else {
            return .manager
        }
        return personality
    }

    // MARK: - Personality-Specific Lines

    /// Drill start announcement. `name`, `minutes`, and `tip` are interpolated.
    func drillStartLine(name: String, minutes: Int, tip: String) -> String {
        switch self {
        case .manager: return "\(name). You've got \(minutes) minutes. \(tip)"
        case .hype:    return "Let's go! \(name)! \(minutes) minutes on the clock. \(tip)"
        case .zen:     return "\(name). Take a breath. You have \(minutes) minutes. \(tip)"
        case .drill:   return "Drop and give me \(name)! \(minutes) minutes. I've seen scarecrows with better coordination. Prove me wrong."
        }
    }

    func midDrillLine(secondsLeft: Int) -> String {
        switch self {
        case .manager: return "Keep going. \(secondsLeft) seconds to go."
        case .hype:    return "You're crushing it! \(secondsLeft) seconds, keep that energy!"
        case .zen:     return "Stay present. \(secondsLeft) seconds remain."
        case .drill:   return "\(secondsLeft) seconds! Is that ALL you've got?! I've seen more intensity from a sleeping cat!"
        }
    }

    var thirtySecondsLine: String {
        switch self {
        case .manager: return "Thirty seconds. Finish strong."
        case .hype:    return "Thirty seconds! Let's go, bring it home!"
        case .zen:     return "Thirty seconds. Stay focused and breathe."
        case .drill:   return "Thirty seconds! If you slack off now I'll make you do this twice tomorrow!"
        }
    }

    var drillCompleteLine: String {
        switch self {
        case .manager: return "Time. How many reps did you get?"
        case .hype:    return "That's time! Great work! How many reps?"
        case .zen:     return "And time. Take a moment. How many reps did you complete?"
        case .drill:   return "TIME! How many reps? And don't you dare lie to me."
        }
    }

    var reflectionLine: String {
        switch self {
        case .manager: return "Quick reflection. How hard was that, 1 to 10?"
        case .hype:    return "Awesome session! Rate that effort, 1 to 10."
        case .zen:     return "Let's reflect. On a scale of 1 to 10, how did that feel?"
        case .drill:   return "Effort rating. 1 to 10. And if you say anything below 5, I know you sandbagged it."
        }
    }

    var sessionCompleteLine: String {
        switch self {
        case .manager: return "Well done. Session complete."
        case .hype:    return "Yes! Session complete! You're a legend!"
        case .zen:     return "Session complete. Be proud of the work you put in today."
        case .drill:   return "Session over. You survived. Barely. Try to be less terrible tomorrow."
        }
    }

    var personalRecordLine: String {
        switch self {
        case .manager: return "New personal record! Great progress."
        case .hype:    return "New personal record! That's what I'm talking about!"
        case .zen:     return "A new personal best. Wonderful."
        case .drill:   return "New record! Even a broken clock is right twice a day. Keep going."
        }
    }

    // MARK: - Milestone Celebration Lines (B8)

    /// Spoken the first time a child hits a named streak milestone.
    func streakMilestoneLine(_ milestone: Int) -> String {
        switch self {
        case .manager:
            switch milestone {
            case 7:   return "Seven days. That's a real habit now. Keep going."
            case 14:  return "Two weeks in. This is how real players are made."
            case 30:  return "Thirty days. That's outstanding consistency."
            case 100: return "One hundred days. You belong in a different conversation now."
            default:  return "\(milestone) days strong. Keep showing up."
            }
        case .hype:
            switch milestone {
            case 7:   return "Seven days! You're on fire! Let's keep this going!"
            case 14:  return "Two weeks of pure dedication! You're unstoppable!"
            case 30:  return "Thirty days! That's legendary! You're built different!"
            case 100: return "One hundred days! ONE HUNDRED! You're a machine!"
            default:  return "\(milestone) days! Absolutely crushing it!"
            }
        case .zen:
            switch milestone {
            case 7:   return "Seven days. The habit is taking root. Stay present."
            case 14:  return "Two weeks. The practice becomes the path."
            case 30:  return "Thirty days. You have chosen consistency. Beautiful."
            case 100: return "One hundred days. This is who you are now."
            default:  return "\(milestone) days. The work continues."
            }
        case .drill:
            switch milestone {
            case 7:   return "Seven days. Finally doing what I told you. Don't stop."
            case 14:  return "Two weeks. I'm almost impressed. Almost."
            case 30:  return "Thirty days. You might actually be taking this seriously."
            case 100: return "One hundred days. Alright. I respect it. Now do two hundred."
            default:  return "\(milestone) days. Keep it up. Don't make me regret saying that."
            }
        }
    }

    /// Spoken when the child's avatar evolves into a new stage.
    func avatarEvolutionLine(to stage: AvatarStage) -> String {
        switch self {
        case .manager:
            return stage == .legend
                ? "You've evolved to Legend. That's the top tier. You earned it."
                : "You've evolved to Pro. The work is paying off. Let's keep climbing."
        case .hype:
            return stage == .legend
                ? "LEGEND STATUS UNLOCKED! You are officially built different!"
                : "PRO level! You're a different player now! Let's goooo!"
        case .zen:
            return stage == .legend
                ? "Legend. The journey has brought you here. Honor it."
                : "Pro. A meaningful step. Stay committed to the practice."
        case .drill:
            return stage == .legend
                ? "Legend, huh. Don't let it go to your head. Back to work."
                : "Pro stage. Welcome to the part where I expect more from you."
        }
    }

    /// Spoken on the first session of a new day (not every session).
    var firstSessionOfDayLine: String {
        switch self {
        case .manager: return "First session of the day. Set the tone."
        case .hype:    return "First one today! Let's get this party started!"
        case .zen:     return "The day's first session. Begin with intention."
        case .drill:   return "First session of the day. Let's see if you're awake yet."
        }
    }

    /// Spoken when the child starts training after a STRESSED or TIRED check-in.
    var afterToughCheckInLine: String {
        switch self {
        case .manager: return "Tough day. Show up anyway. Short session counts too."
        case .hype:    return "Rough day? Training is the reset button. Let's go!"
        case .zen:     return "The day was heavy. The ball is still here for you. Breathe and begin."
        case .drill:   return "Bad day? Good. Prove to yourself it doesn't run you."
        }
    }
}

struct ParentControlsView: View {
    let childId: String
    let childName: String

    @State private var selectedTab = 0

    // Permissions
    @State private var freeTextEnabled = false
    @State private var voiceEnabled = false
    @State private var coachPersonality: CoachPersonality = .manager
    @State private var trainingWindowStart = ""
    @State private var trainingWindowEnd = ""
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var isLoadingSettings = true

    // PIN
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var pinMessage: String?
    @State private var isSavingPin = false

    // Data & Privacy
    @State private var showResetConfirm = false
    @State private var showDeleteChildConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isPerformingAction = false
    @State private var actionMessage: String?

    private let apiClient: APIClientProtocol = APIClient()

    var body: some View {
        Form {
            if isLoadingSettings {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading settings...")
                        Spacer()
                    }
                }
            } else {
                // Tab selector
                Picker("Section", selection: $selectedTab) {
                    Text("Permissions").tag(0)
                    Text("Data & Privacy").tag(1)
                    Text("Child Login").tag(2)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

                switch selectedTab {
                case 0:
                    permissionsTab
                case 1:
                    dataPrivacyTab
                case 2:
                    childLoginTab
                default:
                    EmptyView()
                }

                // Delete parent account (always visible at bottom)
                Section {
                    Button(role: .destructive) {
                        showDeleteAccountConfirm = true
                    } label: {
                        Label("Delete My Account", systemImage: "person.crop.circle.badge.xmark")
                    }
                } footer: {
                    Text("Permanently deletes your parent account and all associated data. This cannot be undone.")
                }
            }
        }
        .navigationTitle("\(childName)'s Controls")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCurrentSettings()
        }
        .alert("Reset Progress?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { Task { await resetProgress() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all training progress for \(childName). This cannot be undone.")
        }
        .alert("Delete Child?", isPresented: $showDeleteChildConfirm) {
            Button("Delete", role: .destructive) { Task { await deleteChild() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(childName)'s profile and all associated data.")
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountConfirm) {
            Button("Delete Everything", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your parent account, all child profiles, and all data. This cannot be undone.")
        }
    }

    // MARK: - Permissions Tab

    @ViewBuilder
    private var permissionsTab: some View {
        Section("Coach Type") {
            ForEach(CoachPersonality.allCases) { personality in
                Button {
                    coachPersonality = personality
                } label: {
                    HStack(spacing: 12) {
                        Image(personality.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(coachPersonality == personality ? Color.dsSecondary : Color.clear, lineWidth: 2)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(personality.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(personality.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if coachPersonality == personality {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.dsSecondary)
                        }
                    }
                }
            }
        }

        Section("Content Controls") {
            Toggle("Free Text Notes", isOn: $freeTextEnabled)
            Text("Allow typed notes in activity logs (recommended for ages 14+)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Voice Commands", isOn: $voiceEnabled)
            Text("Enable voice input for training sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Training Window") {
            TextField("Start time (e.g. 08:00)", text: $trainingWindowStart)
                .keyboardType(.numbersAndPunctuation)
            TextField("End time (e.g. 20:00)", text: $trainingWindowEnd)
                .keyboardType(.numbersAndPunctuation)
            Text("Limit when training sessions can be started")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Notifications") {
            NavigationLink {
                NotificationSettingsView(childId: childId, childName: childName)
            } label: {
                Label("Training Reminders", systemImage: "bell.badge")
            }
        }

        Section {
            Button {
                Task { await savePermissions() }
            } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                    } else {
                        Text(saveSuccess ? "Saved!" : "Save Changes")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Data & Privacy Tab

    @ViewBuilder
    private var dataPrivacyTab: some View {
        Section("Legal") {
            Link(destination: URL(string: "https://pitchdreams.soccer/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: "https://pitchdreams.soccer/terms")!) {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
            Link(destination: URL(string: "https://pitchdreams.soccer/kids-privacy")!) {
                Label("Kids Privacy (COPPA)", systemImage: "figure.child")
            }
        } footer: {
            Text("PitchDreams is designed for youth players with parental supervision. We do not share or sell child data. Third-party analytics are disabled.")
        }

        Section("Export") {
            NavigationLink {
                // Export is a download action; use a simple trigger view
                ExportDataView(childId: childId, childName: childName)
            } label: {
                Label("Export Child Data", systemImage: "square.and.arrow.up")
            }
        }

        Section("Reset") {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset Training Progress", systemImage: "arrow.counterclockwise")
            }
        }

        Section("Remove") {
            Button(role: .destructive) {
                showDeleteChildConfirm = true
            } label: {
                Label("Delete Child Profile", systemImage: "trash")
            }
        }

        if let msg = actionMessage {
            Section {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(msg.contains("Error") ? .red : .green)
            }
        }
    }

    // MARK: - Child Login Tab

    @ViewBuilder
    private var childLoginTab: some View {
        Section {
            SecureField("New PIN (4-6 digits)", text: $newPin)
                .keyboardType(.numberPad)
            SecureField("Confirm PIN", text: $confirmPin)
                .keyboardType(.numberPad)

            if !confirmPin.isEmpty && newPin != confirmPin {
                Label("PINs do not match", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button {
                Task { await savePin() }
            } label: {
                HStack {
                    Spacer()
                    if isSavingPin {
                        ProgressView()
                    } else {
                        Text("Save PIN")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(isSavingPin || newPin.count < 4 || newPin.count > 6 || newPin != confirmPin || !newPin.allSatisfy(\.isNumber))
        } header: {
            Text("Set or Change PIN")
        } footer: {
            Text("Your child uses this PIN along with your email and their nickname to log in.")
        }

        if let msg = pinMessage {
            Section {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(msg.contains("Error") ? .red : .green)
            }
        }
    }

    // MARK: - Actions

    private func loadCurrentSettings() async {
        isLoadingSettings = true
        do {
            let profile: ChildProfileDetail = try await apiClient.request(APIRouter.getProfile(childId: childId))
            voiceEnabled = profile.voiceEnabled
            // Restore coach personality: prefer API value, fall back to UserDefaults
            if let apiPersonality = profile.coachPersonality,
               let personality = CoachPersonality(rawValue: apiPersonality) {
                coachPersonality = personality
                personality.save(forChildId: childId)
            } else {
                coachPersonality = CoachPersonality.saved(forChildId: childId)
            }
        } catch {
            // Non-critical: restore from UserDefaults
            coachPersonality = CoachPersonality.saved(forChildId: childId)
        }
        isLoadingSettings = false
    }

    private func savePermissions() async {
        isSaving = true
        saveSuccess = false
        let body = PermissionsUpdate(
            freeTextEnabled: freeTextEnabled,
            voiceEnabled: voiceEnabled,
            coachPersonality: coachPersonality.rawValue,
            trainingWindowStart: trainingWindowStart.isEmpty ? nil : trainingWindowStart,
            trainingWindowEnd: trainingWindowEnd.isEmpty ? nil : trainingWindowEnd
        )
        do {
            try await apiClient.requestVoid(APIRouter.updateChildPermissions(childId: childId, permissions: body))
            coachPersonality.save(forChildId: childId)
            saveSuccess = true
        } catch {
            // Silently fail; user sees no "Saved!" confirmation
        }
        isSaving = false
    }

    private func savePin() async {
        isSavingPin = true
        pinMessage = nil
        do {
            try await apiClient.requestVoid(APIRouter.setChildPin(childId: childId, pin: newPin))
            pinMessage = "PIN updated successfully."
            newPin = ""
            confirmPin = ""
        } catch {
            pinMessage = "Error: Could not update PIN."
        }
        isSavingPin = false
    }

    private func resetProgress() async {
        isPerformingAction = true
        actionMessage = nil
        do {
            try await apiClient.requestVoid(APIRouter.resetChildProgress(childId: childId))
            actionMessage = "Progress reset successfully."
        } catch {
            actionMessage = "Error: Could not reset progress."
        }
        isPerformingAction = false
    }

    private func deleteChild() async {
        isPerformingAction = true
        actionMessage = nil
        do {
            try await apiClient.requestVoid(APIRouter.deleteChild(childId: childId))
            actionMessage = "Child profile deleted."
        } catch {
            actionMessage = "Error: Could not delete child profile."
        }
        isPerformingAction = false
    }

    private func deleteAccount() async {
        isPerformingAction = true
        do {
            try await apiClient.requestVoid(APIRouter.deleteParentAccount)
            // AuthManager should handle logout via 401 or explicit call
        } catch {
            actionMessage = "Error: Could not delete account."
        }
        isPerformingAction = false
    }
}

// MARK: - Export Data View

private struct ExportDataView: View {
    let childId: String
    let childName: String
    @State private var isExporting = false
    @State private var exportResult: String?
    private let apiClient: APIClientProtocol = APIClient()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.zipper")
                .font(.system(size: 48))
                .foregroundStyle(Color.dsSecondary)

            Text("Export \(childName)'s Data")
                .font(.title3.bold())

            Text("Download all training data, activities, and progress in a portable format.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let result = exportResult {
                Text(result)
                    .font(.subheadline)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await exportData() }
            } label: {
                HStack {
                    if isExporting {
                        ProgressView().tint(.white)
                    } else {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.dsSecondary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isExporting)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exportData() async {
        isExporting = true
        exportResult = nil
        do {
            try await apiClient.requestVoid(APIRouter.exportChildData(childId: childId))
            exportResult = "Export initiated. Check your email for the download link."
        } catch {
            exportResult = "Error: Could not export data."
        }
        isExporting = false
    }
}

#Preview {
    NavigationStack {
        ParentControlsView(childId: "1", childName: "Jude")
    }
}
