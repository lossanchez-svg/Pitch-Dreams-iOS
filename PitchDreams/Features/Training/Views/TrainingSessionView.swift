import SwiftUI

struct TrainingSessionView: View {
    let childId: String
    @StateObject private var viewModel: TrainingViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var coachVoice = CoachVoice()
    @State private var showFullCheckIn = false
    @State private var lastVoiceCommand: String?
    @State private var voiceEnabled = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: TrainingViewModel(childId: childId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.checkInState != nil {
                    sessionModeCard
                    actionButtons
                } else {
                    moodPickerSection
                }

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if speechRecognizer.isListening {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isListening ? .red : .cyan)
                }
            }
        }
        .overlay {
            if viewModel.isCheckingIn {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Checking in...")
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .sheet(isPresented: $showFullCheckIn) {
            FullCheckInSheet(childId: childId, viewModel: viewModel, isPresented: $showFullCheckIn)
        }
        .task {
            await viewModel.loadTodayCheckIn()
            await loadVoiceSetting()
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            processVoiceCommand(newTranscript)
        }
    }

    // MARK: - Voice

    private func loadVoiceSetting() async {
        let apiClient: APIClientProtocol = APIClient()
        if let profile: ChildProfileDetail = try? await apiClient.request(APIRouter.getProfile(childId: childId)) {
            voiceEnabled = profile.voiceEnabled
        }
    }

    private func processVoiceCommand(_ transcript: String) {
        let moodCommands = buildMoodCommands()
        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: moodCommands) {
            lastVoiceCommand = matched.label
            matched.action()
        }
    }

    private func buildMoodCommands() -> [VoiceCommand] {
        moods.map { mood in
            VoiceCommand(label: mood.label, phrases: [mood.name.lowercased(), mood.label.lowercased()]) {
                Task {
                    await viewModel.quickCheckIn(mood: mood.name)
                    if let explanation = viewModel.modeExplanation {
                        coachVoice.speak(explanation, personality: "manager")
                    }
                }
            }
        }
    }

    // MARK: - Mood Picker

    private var moodPickerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                Text("How are you feeling?")
                    .font(.title2.bold())
                Text("Tap a mood or say it out loud with the mic.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(moods, id: \.name) { mood in
                    Button {
                        Task {
                            await viewModel.quickCheckIn(mood: mood.name)
                            if let explanation = viewModel.modeExplanation {
                                coachVoice.speak(explanation, personality: "manager")
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(mood.emoji)
                                .font(.system(size: 36))
                            Text(mood.label)
                                .font(.caption.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isCheckingIn)
                }
            }

            Button {
                showFullCheckIn = true
            } label: {
                Label("Full Check-In", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Session Mode Card

    private var sessionModeCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: modeIcon)
                    .font(.title2)
                    .foregroundStyle(modeSwiftColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.modeDisplayName)
                        .font(.title3.bold())
                }
                Spacer()
                Text(viewModel.modeDisplayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(modeSwiftColor.opacity(0.15))
                    .foregroundStyle(modeSwiftColor)
                    .clipShape(Capsule())
            }

            if let explanation = viewModel.modeExplanation {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink {
                SpaceSelectionView(childId: childId)
            } label: {
                Label("Start Training", systemImage: "figure.run")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            NavigationLink {
                ActivityLogView(childId: childId)
            } label: {
                Label("Log Session", systemImage: "doc.text.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var modeIcon: String {
        switch viewModel.sessionMode {
        case "PEAK": return "bolt.fill"
        case "NORMAL": return "checkmark.circle.fill"
        case "LOW_BATTERY": return "battery.25"
        case "RECOVERY": return "bed.double.fill"
        default: return "questionmark.circle"
        }
    }

    private var modeSwiftColor: Color {
        switch viewModel.sessionMode {
        case "PEAK": return .green
        case "NORMAL": return .blue
        case "LOW_BATTERY": return .yellow
        case "RECOVERY": return .purple
        default: return .gray
        }
    }

    private var moods: [(name: String, emoji: String, label: String)] {
        [
            ("EXCITED", "😄", "Excited"),
            ("FOCUSED", "🎯", "Focused"),
            ("OKAY", "😊", "Okay"),
            ("TIRED", "😴", "Tired"),
            ("STRESSED", "😰", "Stressed"),
        ]
    }
}

#Preview {
    NavigationStack {
        TrainingSessionView(childId: "preview-child")
    }
}
