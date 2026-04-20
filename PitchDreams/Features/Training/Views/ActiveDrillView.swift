import SwiftUI

struct ActiveDrillView: View {
    let childId: String
    @StateObject private var viewModel: ActiveTrainingViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var lastVoiceCommand: String?
    @State private var repBounce = false
    /// Transcripts arriving before this date are discarded (coach voice protection).
    @State private var ignoreTranscriptsUntil: Date = .distantPast
    @Environment(\.dismiss) private var dismiss

    init(childId: String, drills: [DrillDefinition], spaceType: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ActiveTrainingViewModel(
            childId: childId, drills: drills, spaceType: spaceType
        ))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .drilling:
                drillContent
            case .repConfirm:
                repConfirmContent
            case .reflection:
                ReflectionView(viewModel: viewModel, speechRecognizer: speechRecognizer)
            case .complete:
                SessionCompleteView(viewModel: viewModel)
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
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .foregroundStyle(Color.dsSecondary)
                    Text("TRAINING SESSION")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        Task { await speechRecognizer.toggleListening() }
                    } label: {
                        Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                            .foregroundStyle(speechRecognizer.isListening ? .red : Color.dsSecondary)
                            .frame(width: 40, height: 40)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(speechRecognizer.isListening ? "Turn voice commands off" : "Turn voice commands on")

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .frame(width: 40, height: 40)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Exit training session")
                }
            }
        }
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            // Discard transcripts during and shortly after coach speech.
            // The mic stays on (no audio engine disruption) but we ignore
            // anything the recognizer picks up from the coach's voice.
            guard Date() > ignoreTranscriptsUntil else { return }
            processDrillVoiceCommand(newTranscript)
        }
        .task {
            await viewModel.loadProfile()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            // When the coach starts speaking, set a discard window that extends
            // 3 seconds past when it finishes. This covers the full recognition
            // pipeline latency without touching the audio engine.
            viewModel.coachVoice.onWillSpeak = {
                // Extend far into the future; onDidFinishSpeaking narrows it
                ignoreTranscriptsUntil = .distantFuture
            }
            viewModel.coachVoice.onDidFinishSpeaking = {
                // Give the recognizer time to flush buffered coach audio.
                // Keep short so voice input responds quickly after coach finishes.
                ignoreTranscriptsUntil = Date().addingTimeInterval(1.5)
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.coachVoice.onWillSpeak = nil
            viewModel.coachVoice.onDidFinishSpeaking = nil
            viewModel.cleanup()
        }
    }

    // MARK: - Voice Commands

    private func processDrillVoiceCommand(_ transcript: String) {
        // Only process drill commands during drill/repConfirm phases.
        // Reflection has its own voice handler — without this guard,
        // shared phrases like "next"/"done" would fire both handlers.
        guard viewModel.phase == .drilling || viewModel.phase == .repConfirm else { return }

        let commands: [VoiceCommand] = [
            VoiceCommand(label: "Pause", phrases: ["pause", "hold", "wait"]) {
                if viewModel.isTimerRunning {
                    viewModel.pauseTimer()
                }
            },
            VoiceCommand(label: "Resume", phrases: ["resume", "restart", "continue", "start"]) {
                if !viewModel.isTimerRunning && viewModel.phase == .drilling {
                    viewModel.startDrill()
                }
            },
            VoiceCommand(label: "Done", phrases: ["done", "finish", "complete"]) {
                viewModel.completeDrill()
            },
            VoiceCommand(label: "Next", phrases: ["next", "skip"]) {
                viewModel.confirmReps()
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
            VoiceCommand(label: "Cancel", phrases: ["cancel", "stop", "quit"]) {
                dismiss()
            },
        ]

        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
            return
        }

        if let number = VoiceCommandMatcher.extractNumber(from: transcript) {
            lastVoiceCommand = "\(number) reps"
            viewModel.repCount = number
            repBounce.toggle()
        }
    }

    // MARK: - Drill Phase (Redesigned)

    private var drillContent: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drill title section
                VStack(spacing: 4) {
                    Text("ACTIVE DRILL")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Color.dsSecondary.opacity(0.7))

                    Text(viewModel.currentDrill?.name.uppercased() ?? "DRILL")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .tracking(-1)
                        .foregroundStyle(Color.dsOnSurface)
                }
                .padding(.top, 8)

                // Technique animation (when the drill has one authored).
                // Appears between title and timer, eats one spacer, shrinks
                // the timer ring so small phones still fit.
                if let assetId = viewModel.currentDrill?.diagramAnimationAsset,
                   let anim = TechniqueAnimationRegistry.animation(for: assetId) {
                    TechniqueAnimationView(
                        animation: anim,
                        coachVoice: viewModel.coachVoice,
                        voiceoverEnabled: true
                    )
                    .frame(height: 180)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 12)
                }

                Spacer(minLength: 0)

                // Timer ring + avatar. Hide the avatar peek when an authored
                // animation is on-screen — the kinematic figure already
                // carries the "someone training" affordance.
                ZStack {
                    timerRing

                    if viewModel.currentDrill?.diagramAnimationAsset == nil {
                        avatarPeek
                            .offset(x: 120, y: 30)
                    }
                }

                Spacer(minLength: 0)

                // Action row
                actionButtons
                    .padding(.horizontal, Spacing.xxl)

                Spacer().frame(height: 24)

                // Voice footer
                voiceFooter
            }
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        // Shrink when an authored animation is on-screen so small phones
        // (iPhone SE) still fit both elements above the action row.
        let hasAnimation = viewModel.currentDrill?.diagramAnimationAsset != nil
        let ringSize: CGFloat = hasAnimation ? 200 : 260

        return ZStack {
            // Background ring
            Circle()
                .stroke(Color.dsSurfaceContainerHigh, lineWidth: 12)
                .frame(width: ringSize, height: ringSize)

            // Progress ring (orange gradient)
            Circle()
                .trim(from: 0, to: currentTimerProgress)
                .stroke(
                    AngularGradient(
                        colors: [Color.dsAccentOrange, Color.dsAccentOrange.opacity(0.6)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.timeRemaining)
                .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 20)
                .shadow(color: Color.dsAccentOrange.opacity(0.2), radius: 10)

            // Inner glow bg
            Circle()
                .fill(Color.dsSurfaceContainerLowest.opacity(0.4))
                .frame(width: ringSize - 24, height: ringSize - 24)

            // Countdown text
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .tracking(-2)
                    .foregroundStyle(Color.dsOnSurface)
                    .contentTransition(.numericText())

                VStack(spacing: 4) {
                    Text("CURRENT REPS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Color.dsAccentOrange.opacity(0.8))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.repCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                            .scaleEffect(repBounce ? 1.15 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: repBounce)

                        if let drill = viewModel.currentDrill, drill.reps > 0 {
                            Text("/ \(drill.reps)")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dsSurfaceBright)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var avatarPeek: some View {
        let assetName = viewModel.avatarAssetName
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .shadow(color: Color.dsSecondary.opacity(0.3), radius: 12)
        } else {
            // No avatar asset found — skip the peek
            EmptyView()
        }
    }

    private var currentTimerProgress: Double {
        guard let drill = viewModel.currentDrill, drill.duration > 0 else { return 0 }
        return Double(viewModel.timeRemaining) / Double(drill.duration)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.lg) {
            // Pause / Resume
            Button {
                if viewModel.isTimerRunning {
                    viewModel.pauseTimer()
                } else {
                    viewModel.startDrill()
                }
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.dsSecondary.opacity(0.4), lineWidth: 2)
                            .frame(width: 56, height: 56)
                        Image(systemName: viewModel.isTimerRunning ? "pause" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.dsSecondary)
                    }
                    Text(viewModel.isTimerRunning ? "PAUSE" : "START")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .accessibilityLabel(viewModel.isTimerRunning ? "Pause drill timer" : "Start drill timer")
            .accessibilityHint("Double tap to toggle")

            // +1 REP (center, larger)
            Button {
                viewModel.incrementReps()
                repBounce.toggle()
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.dsAccentOrange, Color(hex: "#9D3500")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: Color(hex: "#9D3500"), radius: 0, y: 6)
                            .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 15, y: 8)

                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("+1 REP")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurface)
                }
            }
            .accessibilityLabel("Add one rep")
            .accessibilityHint("Current count: \(viewModel.repCount) reps")

            // Done
            Button {
                viewModel.completeDrill()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.dsSurfaceBright, lineWidth: 2)
                            .frame(width: 56, height: 56)
                        Image(systemName: "checkmark")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    Text("DONE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .accessibilityLabel("Finish drill")
            .accessibilityHint("Complete this drill and move to the next one")
        }
    }

    // MARK: - Voice Footer

    private var voiceFooter: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dsSecondary.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .blur(radius: 6)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.dsSecondary)
                }

                HStack(spacing: 4) {
                    Text("Say")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text("\"Done\"")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("to finish")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.dsSurfaceContainerHigh.opacity(0.6))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.dsOutlineVariant.opacity(0.1), lineWidth: 1)
            )

            // Visualizer dots
            HStack(spacing: 3) {
                ForEach([2, 4, 8, 4, 2], id: \.self) { width in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.dsSecondary.opacity(Double(width) / 10.0))
                        .frame(width: CGFloat(width) * 2, height: 3)
                }
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Rep Confirm (Redesigned)

    private var repConfirmContent: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.dsSecondary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.dsSecondary)
                }
                .dsSecondaryShadow()

                VStack(spacing: 8) {
                    Text("DRILL COMPLETE")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color.dsSecondary)

                    if let drill = viewModel.currentDrill {
                        Text(drill.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                    }
                }

                VStack(spacing: 4) {
                    Text("REPS COMPLETED")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text("\(viewModel.repCount)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                }
                .padding(Spacing.xl)
                .background(Color.dsSurfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .ghostBorder()

                Spacer()

                Button {
                    viewModel.confirmReps()
                } label: {
                    Text(viewModel.isLastDrill ? "GO TO REFLECTION" : "NEXT DRILL")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                }
                .padding(.horizontal, Spacing.xxl)

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let minutes = viewModel.timeRemaining / 60
        let seconds = viewModel.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
