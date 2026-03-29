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
        case .drill: return "Direct and disciplined"
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
                        Image(systemName: personality.icon)
                            .font(.title3)
                            .foregroundStyle(coachPersonality == personality ? .cyan : .secondary)
                            .frame(width: 32)

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
                                .foregroundStyle(.cyan)
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
        } catch {
            // Non-critical: settings will use defaults
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
                .foregroundStyle(Color.accentColor)

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
                .background(Color.accentColor)
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
