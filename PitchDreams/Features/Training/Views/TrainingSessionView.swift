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
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if viewModel.checkInState != nil {
                        sessionModeCard
                        actionButtons
                    } else {
                        moodPickerSection
                    }

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.dsError)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.dsError.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                }
                .padding(Spacing.xl)
                .padding(.bottom, 100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if speechRecognizer.isListening {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("TRAINING")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isListening ? .red : Color.dsSecondary)
                }
            }
        }
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .overlay {
            if viewModel.isCheckingIn {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Color.dsSecondary)
                        Text("Checking in...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    .padding(32)
                    .background(Color.dsSurfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
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
        .navigationDestination(isPresented: $navigateToSpaceSelection) {
            SpaceSelectionView(childId: childId)
        }
    }

    // MARK: - Voice

    private func loadVoiceSetting() async {
        let apiClient: APIClientProtocol = APIClient()
        if let profile: ChildProfileDetail = try? await apiClient.request(APIRouter.getProfile(childId: childId)) {
            voiceEnabled = profile.voiceEnabled
        }
    }

    @State private var navigateToSpaceSelection = false

    private func processVoiceCommand(_ transcript: String) {
        let allCommands = buildMoodCommands() + buildNavigationCommands()
        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: allCommands) {
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

    private func buildNavigationCommands() -> [VoiceCommand] {
        [
            VoiceCommand(label: "Start Training", phrases: ["start training", "start", "let's go", "begin"]) {
                if viewModel.checkInState != nil {
                    navigateToSpaceSelection = true
                }
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]
    }

    // MARK: - Mood Picker

    private var moodPickerSection: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: 8) {
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.dsAccentOrange)
                Text("How are you feeling?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("Tap a mood or say it out loud with the mic.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
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
                            Text(mood.label.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.dsOnSurface)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.dsSurfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .ghostBorder()
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isCheckingIn)
                }
            }

            Button {
                showFullCheckIn = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color.dsSecondary)
                    Text("FULL CHECK-IN")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurface)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dsSurfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .ghostBorder()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Session Mode Card

    private var sessionModeCard: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(modeSwiftColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: modeIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(modeSwiftColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S MODE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text(viewModel.modeDisplayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                }
                Spacer()
                Text(viewModel.modeDisplayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(modeSwiftColor.opacity(0.15))
                    .foregroundStyle(modeSwiftColor)
                    .clipShape(Capsule())
            }

            if let explanation = viewModel.modeExplanation {
                Text(explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            NavigationLink {
                SpaceSelectionView(childId: childId)
            } label: {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 18))
                    Text("START TRAINING")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(Color(hex: "#5B1B00"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsPrimaryShadow()
            }

            NavigationLink {
                ActivityLogView(childId: childId)
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18))
                    Text("LOG SESSION")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(2)
                }
                .foregroundStyle(Color.dsOnSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.dsSurfaceContainerHigh)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .ghostBorder()
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
        case "PEAK": return Color.dsSecondary
        case "NORMAL": return Color.dsSecondary
        case "LOW_BATTERY": return Color.dsTertiaryContainer
        case "RECOVERY": return Color(hex: "#8B5CF6")
        default: return Color.dsOnSurfaceVariant
        }
    }

    private var moods: [(name: String, emoji: String, label: String)] {
        [
            ("EXCITED", "\u{1F604}", "Excited"),
            ("FOCUSED", "\u{1F3AF}", "Focused"),
            ("OKAY", "\u{1F60A}", "Okay"),
            ("TIRED", "\u{1F634}", "Tired"),
            ("STRESSED", "\u{1F630}", "Stressed"),
        ]
    }
}

#Preview {
    NavigationStack {
        TrainingSessionView(childId: "preview-child")
    }
}
