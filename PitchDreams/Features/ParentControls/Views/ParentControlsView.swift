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

    @State private var freeTextEnabled = false
    @State private var voiceEnabled = false
    @State private var coachPersonality: CoachPersonality = .manager
    @State private var trainingWindowStart = ""
    @State private var trainingWindowEnd = ""
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var isLoadingSettings = true

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
        }
        .navigationTitle("\(childName)'s Controls")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCurrentSettings()
        }
    }

    private func loadCurrentSettings() async {
        isLoadingSettings = true
        do {
            let profile: ChildProfileDetail = try await apiClient.request(APIRouter.getProfile(childId: childId))
            voiceEnabled = profile.voiceEnabled
            // Note: freeTextEnabled and coachPersonality are not returned by the profile API yet
            // They save correctly but can't be pre-loaded until the API is updated
        } catch {
            print("Failed to load settings: \(error)")
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
            print("Failed to save permissions: \(error)")
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ParentControlsView(childId: "1", childName: "Jude")
    }
}
