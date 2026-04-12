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
    @State private var navigateToLearn = false
    @State private var showMilestoneModal = false
    @State private var newMilestone: Int?
    @State private var milestoneFreeze = false
    @State private var showFirstSessionGuide = false
    @State private var showEvolutionModal = false
    @State private var evolvedTo: AvatarStage?
    @ObservedObject private var missionsVM = MissionsViewModel.shared
    @State private var completedMission: Mission?
    @AppStorage("hasCompletedFirstSession") private var hasCompletedFirstSession = false
    @State private var showAvatarPicker = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ChildHomeViewModel(childId: childId))
    }

    // MARK: - Derived State

    /// Local override takes precedence (set by AvatarChangeSheet when API isn't available yet)
    private var effectiveAvatarId: String? {
        UserDefaults.standard.string(forKey: "avatarOverride_\(childId)") ?? viewModel.profile?.avatarId
    }

    private var avatarAssetName: String {
        Avatar.assetName(
            for: effectiveAvatarId,
            milestones: viewModel.streakData?.milestones ?? [],
            localMissionXP: missionsVM.localMissionXP
        )
    }

    private var currentStage: AvatarStage {
        AvatarStage.current(
            forMilestones: viewModel.streakData?.milestones ?? [],
            localMissionXP: missionsVM.localMissionXP
        )
    }

    private var resolvedAvatar: Avatar {
        Avatar.resolve(effectiveAvatarId)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.profile == nil {
                        skeletonContent
                            .padding(.horizontal, Spacing.xl)
                    } else {
                        heroSection

                        // Rank + XP badge bar
                        rankBadgeBar
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, -20)
                            .zIndex(1)

                        // Weekly Goals
                        weeklyGoalsCard
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.xl)

                        // Bento stat cards
                        bentoStats
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.lg)

                        // Next Evolution + Start Training
                        nextEvolutionCard
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.xl)

                        // Missions
                        missionsCard
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.xl)

                        if let nudge = viewModel.nudge {
                            coachNudgeCard(nudge)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.top, Spacing.xl)
                        }

                        exploreSection
                            .padding(.top, Spacing.xxl)
                    }
                }
                .padding(.bottom, 140)
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
                HStack(spacing: 10) {
                    avatarThumbnail
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.dsSecondary, lineWidth: 2))

                    Text("PITCH DREAMS")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "bolt.fill")
                        .foregroundStyle(speechRecognizer.isListening ? .red : Color.dsSecondary)
                        .frame(width: 34, height: 34)
                        .background(Color.dsSurfaceContainerHighest.opacity(0.4))
                        .clipShape(Circle())
                }
            }
        }
        .toolbarBackground(Color.dsBackground.opacity(0.6), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
            voiceEnabled = viewModel.profile?.voiceEnabled ?? false
            missionsVM.load(childId: childId)
            checkForMilestones()
            checkFirstSession()
            checkForAvatarEvolution()
        }
        .onReceive(missionsVM.$lastCompleted) { mission in
            guard let mission else { return }
            completedMission = mission
            missionsVM.lastCompleted = nil
        }
        .sheet(item: $completedMission) { mission in
            MissionCompleteModal(mission: mission) {
                completedMission = nil
            }
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
        .sheet(isPresented: $showEvolutionModal) {
            if let stage = evolvedTo {
                let avatar = Avatar.resolve(effectiveAvatarId)
                EvolutionModal(avatar: avatar, newStage: stage) {
                    showEvolutionModal = false
                }
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarChangeSheet(childId: childId) {
                showAvatarPicker = false
                Task { await viewModel.loadData() }
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
        .navigationDestination(isPresented: $navigateToLearn) {
            LearnView(childId: childId)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Layered radial glows for atmospheric depth
            RadialGradient(
                colors: [
                    avatarGlowColor.opacity(0.25),
                    avatarGlowColor.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 300
            )
            .frame(height: 420)

            // Secondary warm glow layer
            RadialGradient(
                colors: [
                    Color.dsAccentOrange.opacity(0.06),
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.6),
                startRadius: 10,
                endRadius: 200
            )
            .frame(height: 420)

            VStack(spacing: 8) {
                // Greeting — small, secondary
                Text("\(viewModel.greeting), \(viewModel.profile?.nickname ?? "player")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .tracking(0.5)
                    .padding(.bottom, 4)

                // Large avatar — tappable to change
                ZStack(alignment: .bottomTrailing) {
                    heroAvatarImage
                        .frame(width: 260, height: 260)
                        .onTapGesture { showAvatarPicker = true }

                    // PRO badge
                    if currentStage.rawValue >= AvatarStage.pro.rawValue {
                        VStack(spacing: 4) {
                            Text(currentStage.title.uppercased())
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(3)
                                .foregroundStyle(Color.dsSecondary)

                            HStack(spacing: 4) {
                                ForEach(AvatarStage.allCases, id: \.rawValue) { stage in
                                    Circle()
                                        .fill(stage <= currentStage ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                                        .frame(width: 6, height: 6)
                                        .shadow(color: stage <= currentStage ? Color.dsSecondary.opacity(0.8) : .clear, radius: 4)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.dsSurfaceContainerHighest.opacity(0.9))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dsSecondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                // Next evolution preview (right side overlay)
            }
            .padding(.top, 24)

            // Next evolution silhouette
            if currentStage != .legend {
                nextEvolutionPreview
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var heroAvatarImage: some View {
        if UIImage(named: avatarAssetName) != nil {
            Image(avatarAssetName)
                .resizable()
                .scaledToFit()
                .shadow(color: avatarGlowColor.opacity(0.2), radius: 30)
        } else {
            Image(systemName: "figure.soccer")
                .font(.system(size: 80))
                .foregroundStyle(Color.dsSecondary)
                .frame(width: 260, height: 260)
                .background(Color.dsSecondary.opacity(0.08))
                .clipShape(Circle())
        }
    }

    private var nextEvolutionPreview: some View {
        VStack(spacing: 8) {
            let nextStage = currentStage == .rookie ? AvatarStage.pro : AvatarStage.legend
            let nextAsset = resolvedAvatar.assetName(stage: nextStage)

            if UIImage(named: nextAsset) != nil {
                Image(nextAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .grayscale(1)
                    .opacity(0.4)
            } else {
                Circle()
                    .fill(Color.dsSurfaceContainerHighest)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.4))
                    )
            }

            Text(daysToNextEvolution)
                .font(.system(size: 8, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
        .padding(12)
        .background(Color.dsSurfaceContainer.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 16)
    }

    private var daysToNextEvolution: String {
        let nextMilestone = currentStage == .rookie ? AvatarStage.pro.unlockMilestone : AvatarStage.legend.unlockMilestone
        let current = viewModel.streakData?.milestones.max() ?? 0
        let remaining = max(0, nextMilestone - current)
        return "\(remaining) more\ndays to\nunlock"
    }

    private var avatarGlowColor: Color {
        switch resolvedAvatar {
        case .panther: return Color(hex: "#8B5CF6") // violet
        case .wolf: return Color.dsSecondary
        case .lion: return Color.dsAccentOrange
        case .eagle: return Color.dsSecondary
        case .fox: return Color.dsAccentOrange
        case .shark: return Color.dsSecondary
        case .bear: return Color.dsTertiaryContainer
        case .default: return Color.dsSecondary
        }
    }

    // MARK: - Avatar Thumbnail (toolbar)

    @ViewBuilder
    private var avatarThumbnail: some View {
        if UIImage(named: avatarAssetName) != nil {
            Image(avatarAssetName)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "figure.soccer")
                .font(.caption)
                .foregroundStyle(Color.dsSecondary)
                .frame(width: 34, height: 34)
                .background(Color.dsSecondary.opacity(0.12))
        }
    }

    // MARK: - Rank Badge Bar

    private var rankBadgeBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT RANK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Text("\(resolvedAvatar.displayName.uppercased()) \(currentStage.title.uppercased())")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .italic()
                    .foregroundStyle(Color.dsPrimaryPeach)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("XP LEVEL")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Text("LVL \(missionsVM.localMissionXP / 10 + 1)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(Color.dsSurfaceContainerLow.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Weekly Goals Card

    private var weeklyGoalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Goals")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsSecondary)
            }

            let completed = missionsVM.weeklyMissions.filter(\.isCompleted).count
            let total = max(missionsVM.weeklyMissions.count, 3)

            Text("\(completed) of \(total) sessions complete")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.dsSurfaceContainerHighest)
                        .frame(height: 12)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.dsSecondary, Color(hex: "#34D9EC")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(total > 0 ? completed : 0) / CGFloat(max(total, 1))), height: 12)
                        .shadow(color: Color.dsSecondary.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 12)
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Bento Stats

    private var bentoStats: some View {
        HStack(spacing: 12) {
            // Training Streak
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsAccentOrange)
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.dsAccentOrange.opacity(0.1))
                }

                Text("TRAINING\nSTREAK")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineSpacing(2)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.streakCount)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("DAYS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dsSurfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()

            // Skill Level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsSecondary)
                    Spacer()
                    Image(systemName: "medal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.dsSecondary.opacity(0.1))
                }

                Text("SKILL\nLEVEL")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineSpacing(2)

                Text(skillGrade)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dsSurfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()
        }
    }

    private var skillGrade: String {
        let streak = viewModel.streakCount
        if streak >= 30 { return "A+" }
        if streak >= 14 { return "A" }
        if streak >= 7 { return "B+" }
        if streak >= 3 { return "B" }
        if streak >= 1 { return "C" }
        return "C-"
    }

    // MARK: - Next Evolution Card

    private var nextEvolutionCard: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.dsSecondary)
                Text("NEXT EVOLUTION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color.dsSecondary)
                Spacer()
            }

            HStack(spacing: Spacing.lg) {
                // Next avatar preview
                let nextStage = currentStage == .rookie ? AvatarStage.pro : AvatarStage.legend
                let nextAsset = resolvedAvatar.assetName(stage: nextStage)

                ZStack {
                    Circle()
                        .fill(Color.dsSurfaceContainerLowest)
                        .frame(width: 64, height: 64)
                    if UIImage(named: nextAsset) != nil {
                        Image(nextAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .grayscale(0.6)
                            .opacity(0.6)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.4))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentStage == .legend ? "MAX STAGE" : "\(resolvedAvatar.displayName.uppercased()) \(currentStage == .rookie ? "PRO" : "LEGEND")")")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text(daysToNextEvolution.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                Spacer()
            }

            // Start Training CTA
            NavigationLink {
                TrainingSessionView(childId: childId)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("START TRAINING")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(Color(hex: "#5B1B00"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(DSGradient.primaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsPrimaryShadow()
            }
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
        .ghostBorder()
    }

    // MARK: - Stats Band (kept for backward compat, no longer shown in main layout)

    private var statsBand: some View {
        HStack(spacing: 0) {
            // Consistency ring (left)
            ZStack {
                Circle()
                    .stroke(Color.dsSurfaceContainerHighest, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        Color.dsSecondary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: ringProgress)

                VStack(spacing: 1) {
                    Text("\(viewModel.streakCount)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dsAccentOrange)
                }
            }
            .frame(width: 72, height: 72)

            // Stat chips (right)
            HStack(spacing: 0) {
                Spacer()
                statChip(icon: "bolt", color: .dsSecondary, label: "Target: \(30)")
                Spacer()
                statChip(icon: "chart.bar.fill", color: .dsTertiaryContainer, label: "\(progressPercent)%")
                Spacer()
                statChip(icon: "shield.fill", color: .dsError, label: "Freezes: \(viewModel.freezeCount)")
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainerLow.opacity(0.8))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
    }

    private func statChip(icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    private var ringProgress: Double {
        guard 30 > 0 else { return 0 }
        return min(1.0, Double(viewModel.streakCount) / 30.0)
    }

    private var progressPercent: Int {
        Int(ringProgress * 100)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: Spacing.lg) {
            NavigationLink {
                TrainingSessionView(childId: childId)
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "figure.run")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: "#5B1B00"))
                    }
                    Text("START TRAINING")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "#5B1B00"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(DSGradient.primaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsPrimaryShadow()
            }
            .buttonStyle(.plain)

            NavigationLink {
                QuickLogView(childId: childId)
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: "#00363C"))
                    }
                    Text("LOG SESSION")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "#00363C"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(DSGradient.secondaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsSecondaryShadow()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Missions Card

    private var missionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("MISSIONS")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.dsOnSurface)
                Spacer()
                NavigationLink {
                    MissionsDetailView(childId: childId)
                } label: {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.dsSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dsSecondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            let completed = missionsVM.weeklyMissions.filter(\.isCompleted).count
            let total = max(missionsVM.weeklyMissions.count, 3)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(completed) of \(total) missions complete")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.dsOnSurface)
                    Spacer()
                    Text("\(total > 0 ? completed * 100 / total : 0)%")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color.dsSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.dsSurfaceContainerHighest)
                            .frame(height: 16)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.dsSecondary, Color(hex: "#34D9EC")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(total > 0 ? completed : 0) / CGFloat(total), height: 16)
                            .shadow(color: Color.dsSecondary.opacity(0.5), radius: 10)
                    }
                }
                .frame(height: 16)
            }
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Coach Nudge

    private func coachNudgeCard(_ nudge: CoachNudge) -> some View {
        HStack(alignment: .bottom, spacing: Spacing.lg) {
            // Coach portrait
            coachPortrait
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.dsTertiaryContainer, lineWidth: 3)
                        .padding(.top, 56) // bottom edge only
                )

            // Speech bubble
            VStack(alignment: .leading, spacing: 8) {
                Text("\"\(nudge.message)\"")
                    .font(.system(size: 14, weight: .regular))
                    .italic()
                    .foregroundStyle(Color.dsOnSurface)
                    .lineSpacing(6)

                Text("-- \(CoachPersonality.current.coachName.uppercased())")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.dsTertiaryContainer)
            }
            .padding(Spacing.lg)
            .background(Color.dsSurfaceContainerHigh)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
    }

    @ViewBuilder
    private var coachPortrait: some View {
        Image(CoachPersonality.current.imageName)
            .resizable()
            .scaledToFill()
    }

    // MARK: - Explore

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("EXPLORE SKILLS")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.dsOnSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .padding(.horizontal, Spacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.lg) {
                    NavigationLink {
                        FirstTouchView(childId: childId)
                    } label: {
                        exploreSkillCard(title: "First Touch", color: .dsAccentOrange, icon: "shoe.fill")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SkillTrackView(childId: childId)
                    } label: {
                        exploreSkillCard(title: "Skills", color: .dsSecondary, icon: "star.fill")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        LearnView(childId: childId)
                    } label: {
                        exploreSkillCard(title: "Learn", color: Color(hex: "#8B5CF6"), icon: "book.fill")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func exploreSkillCard(title: String, color: Color, icon: String = "soccerball") -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background with colored accent glow
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.dsSurfaceContainer)
                .overlay(
                    ZStack {
                        // Center icon as visual content
                        Image(systemName: icon)
                            .font(.system(size: 44))
                            .foregroundStyle(color.opacity(0.2))
                            .offset(y: -20)

                        // Colored accent glow
                        RadialGradient(
                            colors: [color.opacity(0.2), color.opacity(0.05), .clear],
                            center: .init(x: 0.5, y: 0.35),
                            startRadius: 5,
                            endRadius: 90
                        )

                        // Bottom fade for text readability
                        LinearGradient(
                            colors: [Color.dsBackground.opacity(0.95), Color.dsBackground.opacity(0.3), .clear],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    }
                )

            // Content
            VStack(alignment: .leading) {
                Spacer()
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurface)
            }
            .padding(14)
        }
        .frame(width: 140, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView(width: 200, height: 22)
                SkeletonView(width: 140, height: 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SkeletonStreakRing()
            SkeletonQuickActions()
            SkeletonCard()

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

    // MARK: - Voice

    private func processVoiceCommand(_ transcript: String) {
        let commands: [VoiceCommand] = [
            VoiceCommand(label: "Start Training", phrases: ["start training", "let's train", "let's go", "begin", "start"]) {
                navigateToTraining = true
            },
            VoiceCommand(label: "Log Session", phrases: ["log session", "log it", "quick log", "log"]) {
                navigateToQuickLog = true
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]
        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
        }
    }

    // MARK: - Milestone Logic

    private func checkForAvatarEvolution() {
        guard effectiveAvatarId != nil else { return }
        let milestones = viewModel.streakData?.milestones ?? []
        let currentStage = AvatarStage.current(
            forMilestones: milestones,
            localMissionXP: missionsVM.localMissionXP
        )

        let storageKey = "lastSeenAvatarStage_\(childId)"
        let lastSeenRaw = UserDefaults.standard.integer(forKey: storageKey)
        if lastSeenRaw == 0 {
            UserDefaults.standard.set(currentStage.rawValue, forKey: storageKey)
            return
        }

        let lastSeen = AvatarStage(rawValue: lastSeenRaw) ?? .rookie
        if currentStage > lastSeen {
            evolvedTo = currentStage
            showEvolutionModal = true
            UserDefaults.standard.set(currentStage.rawValue, forKey: storageKey)
        }
    }

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
        guard !hasCompletedFirstSession else { return }
        guard viewModel.profile != nil else { return }

        let hasAnyActivity = viewModel.streakCount > 0
            || viewModel.todayCheckIn != nil
            || (viewModel.streakData?.freezesUsed ?? 0) > 0

        if !hasAnyActivity {
            // Don't auto-show — too aggressive. Let users tap "Start Training" instead.
        }
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
}

#Preview {
    NavigationStack {
        ChildHomeView(childId: "preview-child")
            .environmentObject(AuthManager())
    }
}
