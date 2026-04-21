import SwiftUI
import Combine

struct FirstTouchView: View {
    let childId: String
    @StateObject private var viewModel: FirstTouchViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var coachVoice = CoachVoice()
    @State private var lastVoiceCommand: String?
    @State private var voiceEnabled = false

    // Personal best + XP state
    @State private var showPRCelebration = false
    @State private var showXPToast = false
    @State private var showPBToast = false

    // Timer challenge state
    @State private var timerActive = false
    @State private var timerRemaining: Int = 30
    @State private var timerCancellable: AnyCancellable?

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: FirstTouchViewModel(childId: childId))
    }

    var body: some View {
        Group {
            if viewModel.activeDrillKey != nil {
                activeDrillView
            } else {
                drillSelectionView
            }
        }
        .celebration(isPresented: $showPRCelebration)
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                XPEarnedToast(amount: viewModel.xpEarned, isPresented: $showXPToast)
                if showPBToast, let metric = viewModel.personalBestMetric {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.dsTertiaryContainer)
                        Text("New PB! \(metric): \(viewModel.activeCount)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsTertiaryContainer)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.dsTertiaryContainer.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.dsTertiaryContainer.opacity(0.3), lineWidth: 1))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showPBToast = false }
                        }
                    }
                }
            }
            .padding(.top, 60)
        }
        .safeAreaInset(edge: .bottom) {
            if voiceEnabled && viewModel.activeDrillKey != nil {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationTitle("First Touch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.activeDrillKey != nil {
                    Button {
                        Task { await speechRecognizer.toggleListening() }
                    } label: {
                        Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                            .foregroundStyle(speechRecognizer.isListening ? .red : Color.dsSecondary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadStats()
            await loadVoiceSetting()
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty, viewModel.activeDrillKey != nil else { return }
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
        let commands = buildDrillVoiceCommands()
        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
            return
        }
        // Try to extract a number for setting count
        if let number = VoiceCommandMatcher.extractNumber(from: transcript) {
            lastVoiceCommand = "\(number) reps"
            viewModel.activeCount = number
        }
    }

    private func buildDrillVoiceCommands() -> [VoiceCommand] {
        [
            VoiceCommand(label: "Save", phrases: ["save", "done", "finish", "complete"]) {
                Task { await viewModel.saveDrill() }
            },
            VoiceCommand(label: "Cancel", phrases: ["cancel", "stop", "quit"]) {
                viewModel.cancelDrill()
                stopTimerChallenge()
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]
    }

    // MARK: - Timer Challenge

    private func startTimerChallenge() {
        viewModel.activeCount = 0
        timerRemaining = 30
        timerActive = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timerRemaining > 0 {
                    timerRemaining -= 1
                } else {
                    timerActive = false
                    timerCancellable?.cancel()
                    timerCancellable = nil
                    // Auto-save when timer ends
                    Task { await viewModel.saveDrill() }
                }
            }
    }

    private func stopTimerChallenge() {
        timerActive = false
        timerRemaining = 30
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Drill Selection

    private var drillSelectionView: some View {
        List {
            // Atmospheric glow
            Section {
                RadialGradient(
                    colors: [
                        Color.dsAccentOrange.opacity(0.15),
                        Color.dsAccentOrange.opacity(0.04),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 10,
                    endRadius: 250
                )
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Personal bests
            if viewModel.jugglingBest > 0 || viewModel.wallBallBest > 0 {
                Section("Personal Bests") {
                    if viewModel.jugglingBest > 0 {
                        LabeledContent("Juggling Best") {
                            Text("\(viewModel.jugglingBest) reps")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.dsAccentOrange)
                        }
                    }
                    if viewModel.wallBallBest > 0 {
                        LabeledContent("Wall Ball Best") {
                            Text("\(viewModel.wallBallBest) reps")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.dsSecondary)
                        }
                    }
                }
            }

            // Juggling drills
            Section("Juggling") {
                ForEach(FirstTouchViewModel.jugglingDrills, id: \.0) { key, name in
                    drillButton(key: key, name: name, icon: "soccerball", color: Color.dsAccentOrange)
                }
            }

            // Wall ball drills
            Section("Wall Ball") {
                ForEach(FirstTouchViewModel.wallBallDrills, id: \.0) { key, name in
                    drillButton(key: key, name: name, icon: "rectangle.portrait.and.arrow.right", color: Color.dsSecondary)
                }
            }

            // History
            if !viewModel.drillStats.isEmpty {
                Section("Recent Stats") {
                    ForEach(viewModel.drillStats.prefix(5)) { stat in
                        HStack {
                            Text(stat.drillKey.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline)
                            Spacer()
                            Text("\(stat.totalAttempts) attempts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadStats()
        }
        .overlay {
            if viewModel.isLoading && viewModel.drillStats.isEmpty {
                ProgressView()
            }
        }
    }

    private func drillButton(key: String, name: String, icon: String, color: Color) -> some View {
        Button {
            viewModel.startDrill(key)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if let stat = viewModel.drillStats.first(where: { $0.drillKey == key }) {
                        Text("Best: \(stat.totalAttempts) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(color)
            }
        }
    }

    // MARK: - Active Drill

    private var activeDrillView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(viewModel.activeDrillKey?.replacingOccurrences(of: "_", with: " ").capitalized ?? "")
                .font(.title2.weight(.semibold))

            // Authored technique animation when the drill key resolves to
            // a registered animation. FirstTouch drills live outside
            // DrillDefinition, so the mapping is via drill-key lookup.
            if let key = viewModel.activeDrillKey,
               let anim = TechniqueAnimationRegistry.animation(forFirstTouchDrillKey: key) {
                TechniqueAnimationView(
                    animation: anim,
                    coachVoice: CoachVoice(),
                    voiceoverEnabled: false
                )
                .frame(height: 140)
                .padding(.horizontal, 20)
            }

            // Timer display when challenge is active
            if timerActive {
                Text("\(timerRemaining)s")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(timerRemaining <= 5 ? Color.dsError : Color.dsSecondary)
                    .contentTransition(.numericText())
            }

            // Big counter
            Text("\(viewModel.activeCount)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsAccentOrange)
                .contentTransition(.numericText())

            // Tap button
            Button {
                withAnimation(.spring(response: 0.2)) {
                    viewModel.incrementCount()
                }
            } label: {
                Text("TAP")
                    .font(.title.bold())
                    .frame(width: 160, height: 160)
                    .background(DSGradient.orangeAccent)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .applyHapticFeedback(trigger: viewModel.activeCount)

            // 30s Challenge button
            if !timerActive {
                Button {
                    startTimerChallenge()
                } label: {
                    Label("30s Challenge", systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.dsSecondary.opacity(0.15))
                        .foregroundStyle(Color.dsSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 24) {
                Button {
                    viewModel.cancelDrill()
                    stopTimerChallenge()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task {
                        await viewModel.saveDrill()
                        stopTimerChallenge()
                        if viewModel.saveSuccess {
                            // Show XP toast
                            showXPToast = true
                            // PB celebration if new personal best
                            if viewModel.isNewPersonalBest {
                                showPRCelebration = true
                                showPBToast = true
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                if voiceEnabled {
                                    let persona = CoachPersonality.current
                                    coachVoice.speak(persona.personalRecordLine, personality: persona.rawValue)
                                }
                            }
                        }
                    }
                } label: {
                    Text(viewModel.saveSuccess ? "Saved!" : "Save \(viewModel.activeCount) reps")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.dsAccentOrange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.activeCount == 0 || viewModel.isSaving)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)

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
    }

    // MARK: - Helpers

    private func bestForActiveDrill() -> Int? {
        guard let key = viewModel.activeDrillKey,
              let stat = viewModel.drillStats.first(where: { $0.drillKey == key }) else {
            return nil
        }
        return stat.totalAttempts
    }
}

// MARK: - Haptic Feedback Modifier

private struct HapticFeedbackModifier: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.sensoryFeedback(.impact, trigger: trigger)
        } else {
            content
        }
    }
}

extension View {
    func applyHapticFeedback(trigger: Int) -> some View {
        modifier(HapticFeedbackModifier(trigger: trigger))
    }
}

#Preview {
    NavigationStack {
        FirstTouchView(childId: "preview-child")
    }
}
