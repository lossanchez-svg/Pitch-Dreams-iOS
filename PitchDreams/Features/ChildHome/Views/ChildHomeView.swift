import SwiftUI

struct ChildHomeView: View {
    let childId: String
    @StateObject private var viewModel: ChildHomeViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @EnvironmentObject var authManager: AuthManager
    @State private var lastVoiceCommand: String?
    @State private var voiceEnabled = false
    @State private var navigateToTraining = false
    @State private var navigateToQuickLog = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ChildHomeViewModel(childId: childId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                welcomeSection
                streakCard
                quickActions
                checkInStatus

                if let nudge = viewModel.nudge {
                    coachNudgeCard(nudge)
                }

                exploreSection
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if voiceEnabled {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationTitle(viewModel.profile?.nickname ?? "Home")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if voiceEnabled {
                    Button {
                        speechRecognizer.toggleListening()
                    } label: {
                        Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                            .foregroundStyle(speechRecognizer.isListening ? .red : .primary)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.circle")
                        .font(.title3)
                }
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
            voiceEnabled = viewModel.profile?.voiceEnabled ?? false
        }
        .overlay {
            if viewModel.isLoading && viewModel.profile == nil {
                ProgressView("Loading...")
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            processVoiceCommand(newTranscript)
        }
        .background {
            NavigationLink(isActive: $navigateToTraining) {
                TrainingSessionView(childId: childId)
            } label: {
                EmptyView()
            }
            .hidden()

            NavigationLink(isActive: $navigateToQuickLog) {
                QuickLogView(childId: childId)
            } label: {
                EmptyView()
            }
            .hidden()
        }
    }

    // MARK: - Voice

    private func processVoiceCommand(_ transcript: String) {
        let commands: [VoiceCommand] = [
            VoiceCommand(label: "Start Training", phrases: ["start training", "train", "let's train"]) {
                navigateToTraining = true
            },
            VoiceCommand(label: "Log Session", phrases: ["log session", "log it", "quick log"]) {
                navigateToQuickLog = true
            },
        ]
        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
        }
    }

    // MARK: - Welcome

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.greeting), \(viewModel.profile?.nickname ?? "player")!")
                .font(.title2.bold())
            Text("Every session counts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Streak

    private var streakCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(flameEmoji)
                        .font(.system(size: 44))
                    Text("\(viewModel.streakCount)")
                        .font(.title.bold())
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                    Text("day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80)

                Divider()
                    .frame(height: 60)

                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.freezeCount > 0 {
                        Label("\(viewModel.freezeCount) freezes available", systemImage: "shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                    }

                    if let milestones = viewModel.streakData?.milestones, !milestones.isEmpty {
                        Label("Best: \(milestones.max() ?? 0) days", systemImage: "trophy.fill")
                            .font(.subheadline)
                            .foregroundStyle(.yellow)
                    }

                    Text(streakMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var flameEmoji: String {
        let count = viewModel.streakCount
        if count == 0 { return "💤" }
        if count < 7 { return "✨" }
        return "🔥"
    }

    private var streakMessage: String {
        let count = viewModel.streakCount
        if count == 0 { return "Start your streak today!" }
        if count < 3 { return "Building momentum..." }
        if count < 7 { return "Keep it going!" }
        if count < 14 { return "Great consistency!" }
        return "Outstanding dedication!"
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink {
                TrainingSessionView(childId: childId)
            } label: {
                Label("Start Training", systemImage: "figure.run")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            NavigationLink {
                QuickLogView(childId: childId)
            } label: {
                Label("Log Session", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Check-in Status

    private var checkInStatus: some View {
        Group {
            if viewModel.hasCheckedInToday {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Checked in today")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if let mode = viewModel.todayCheckIn?.mode {
                        Text(modeLabel(mode))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(modeColor(mode).opacity(0.15))
                            .foregroundStyle(modeColor(mode))
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                NavigationLink {
                    TrainingSessionView(childId: childId)
                } label: {
                    HStack {
                        Image(systemName: "heart.text.clipboard")
                            .foregroundStyle(.cyan)
                        Text("Check in before training")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Coach Nudge

    private func coachNudgeCard(_ nudge: CoachNudge) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundStyle(.cyan)
                Text(nudge.title)
                    .font(.headline)
            }
            Text(nudge.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(nudge.actionLabel) {
                // Action handled in future
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.cyan)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Explore

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore")
                .font(.headline)

            NavigationLink {
                FirstTouchView(childId: childId)
            } label: {
                exploreCard(title: "First Touch", icon: "soccerball", color: .orange, subtitle: "Juggling & wall ball drills")
            }

            HStack(spacing: 12) {
                NavigationLink {
                    SkillTrackView(childId: childId)
                } label: {
                    exploreCard(title: "Scanning", icon: "eye.fill", color: .cyan, subtitle: "See the field early")
                }

                NavigationLink {
                    SkillTrackView(childId: childId)
                } label: {
                    exploreCard(title: "Planning", icon: "brain.fill", color: .purple, subtitle: "Think ahead")
                }
            }
        }
    }

    private func exploreCard(title: String, icon: String, color: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func modeLabel(_ mode: String) -> String {
        switch mode {
        case "PEAK": return "Peak Day"
        case "NORMAL": return "Normal"
        case "LOW_BATTERY": return "Low Battery"
        case "RECOVERY": return "Recovery"
        default: return mode
        }
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "PEAK": return .green
        case "NORMAL": return .blue
        case "LOW_BATTERY": return .yellow
        case "RECOVERY": return .purple
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        ChildHomeView(childId: "preview-child")
            .environmentObject(AuthManager())
    }
}
