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
    @State private var showMilestoneModal = false
    @State private var newMilestone: Int?
    @State private var milestoneFreeze = false
    @State private var showFirstSessionGuide = false
    @AppStorage("hasCompletedFirstSession") private var hasCompletedFirstSession = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ChildHomeViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading && viewModel.profile == nil {
                        skeletonContent
                    } else {
                        welcomeSection
                        ConsistencyRingView(
                            streak: viewModel.streakCount,
                            maxStreak: 30,
                            freezes: viewModel.freezeCount
                        )
                        quickActions
                        checkInStatus

                        if let nudge = viewModel.nudge {
                            coachNudgeCard(nudge)
                        }

                        exploreSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if speechRecognizer.isListening {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationTitle(viewModel.profile?.nickname ?? "Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isListening ? .red : .cyan)
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
            checkForMilestones()
            checkFirstSession()
        }
        .fullScreenCover(isPresented: $showFirstSessionGuide) {
            FirstSessionGuideView(childId: childId) {
                hasCompletedFirstSession = true
                showFirstSessionGuide = false
                Task { await viewModel.loadData() }
            }
        }
        .sheet(isPresented: $showMilestoneModal) {
            if let milestone = newMilestone {
                StreakMilestoneModal(
                    milestone: milestone,
                    freezeAwarded: milestoneFreeze
                ) {
                    showMilestoneModal = false
                    recordMilestone(milestone)
                }
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            processVoiceCommand(newTranscript)
        }
        .navigationDestination(isPresented: $navigateToTraining) {
            TrainingSessionView(childId: childId)
        }
        .navigationDestination(isPresented: $navigateToQuickLog) {
            QuickLogView(childId: childId)
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
        HStack(spacing: 14) {
            avatarImage
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.greeting), \(viewModel.profile?.nickname ?? "player")!")
                    .font(.title2.bold())
                Text("Every session counts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let avatarId = viewModel.profile?.avatarId,
           UIImage(named: avatarId) != nil {
            Image(avatarId)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "figure.soccer")
                .font(.title)
                .foregroundStyle(.cyan)
                .frame(width: 52, height: 52)
                .background(.cyan.opacity(0.12))
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        ConsistencyRingView(
            streak: viewModel.streakCount,
            maxStreak: 30,
            freezes: viewModel.freezeCount
        )
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
        HStack(alignment: .top, spacing: 12) {
            coachPortrait
                .frame(width: 44, height: 44)
                .clipShape(Circle())

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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var coachPortrait: some View {
        if UIImage(named: "Coach") != nil {
            Image("Coach")
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.title)
                .foregroundStyle(.cyan)
                .frame(width: 44, height: 44)
                .background(.cyan.opacity(0.12))
        }
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
        .cardStyle()
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: 20) {
            // Welcome skeleton
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView(width: 200, height: 22)
                SkeletonView(width: 140, height: 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SkeletonStreakRing()
            SkeletonQuickActions()
            SkeletonCard()

            // Explore skeleton
            VStack(alignment: .leading, spacing: 12) {
                SkeletonView(width: 80, height: 18)
                SkeletonCard()
                HStack(spacing: 12) {
                    SkeletonCard()
                    SkeletonCard()
                }
            }
        }
    }

    // MARK: - Milestone Logic

    private func checkForMilestones() {
        guard let streakData = viewModel.streakData else { return }
        let milestones = [7, 14, 30, 50, 100]
        let achieved = Set(streakData.milestones)
        let streakCount = viewModel.streakCount

        for m in milestones {
            if streakCount >= m && !achieved.contains(m) {
                newMilestone = m
                milestoneFreeze = milestones.firstIndex(of: m).map { $0 % 2 == 0 } ?? false
                showMilestoneModal = true
                break
            }
        }
    }

    private func checkFirstSession() {
        // Only show for truly new users who have never completed the guide
        // AND have no streak data at all (no sessions ever logged)
        guard !hasCompletedFirstSession else { return }
        guard viewModel.profile != nil else { return }

        // If there's any streak data (even 0 freezes), the account has been used
        // Only show guide if streakData hasn't loaded yet OR shows completely fresh account
        let hasAnyActivity = viewModel.streakCount > 0
            || viewModel.todayCheckIn != nil
            || (viewModel.streakData?.freezesUsed ?? 0) > 0

        if !hasAnyActivity {
            // Still might have sessions — check directly
            // For now, skip the guide for any account that has data loading
            // The guide is opt-in via the home screen, not forced
        }
        // Don't auto-show — too aggressive. Let users tap "Start Training" instead.
    }

    private func recordMilestone(_ milestone: Int) {
        Task {
            let apiClient: APIClientProtocol = APIClient()
            let body = MilestoneBody(milestone: milestone)
            let _: MilestoneResult? = try? await apiClient.request(
                APIRouter.recordMilestone(childId: childId, body: body)
            )
        }
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
