import SwiftUI

struct ProgressDashboardView: View {
    let childId: String
    @StateObject private var viewModel: ProgressViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ProgressViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if viewModel.isLoading && viewModel.sessions.isEmpty {
                        SkeletonStatGrid()
                        SkeletonCard()
                        SkeletonCard()
                    } else if viewModel.sessions.isEmpty && viewModel.streakData == nil {
                        emptyState
                    } else {
                        heroGlow
                        statsGrid
                        streakSection
                        recentSessionsSection
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("PROGRESS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Glow

    private var heroGlow: some View {
        VStack(spacing: 8) {
            Text("YOUR JOURNEY")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.dsOnSurfaceVariant)

            Text("Keep the momentum going")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(HeroGlowView(color: .dsSecondary))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCardView(title: "Current Streak", value: "\(viewModel.currentStreak)", unit: "days", icon: "flame.fill", color: .dsAccentOrange)
            StatCardView(title: "Max Streak", value: "\(viewModel.maxStreak)", unit: "days", icon: "trophy.fill", color: .dsTertiaryContainer)
            StatCardView(title: "This Month", value: "\(viewModel.thisMonthSessions)", unit: "sessions", icon: "calendar", color: .dsSecondary)
            StatCardView(title: "Total Sessions", value: "\(viewModel.totalSessions)", unit: "sessions", icon: "figure.run", color: .dsSecondary)
            StatCardView(title: "Training Time", value: viewModel.formattedTotalTime, icon: "clock.fill", color: .dsSecondary)
            StatCardView(title: "Avg RPE", value: viewModel.averageEffort > 0 ? String(format: "%.1f", viewModel.averageEffort) : "--", unit: "/ 10", icon: "bolt.fill", color: .dsAccentOrange)
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeaderView("STREAK DETAILS")

            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.dsSecondary)
                    Text("\(viewModel.freezesAvailable)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("FREEZES")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.dsSurfaceContainerHighest)
                    .frame(width: 1, height: 50)

                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.dsTertiaryContainer)
                    Text("\(viewModel.milestonesAchieved.count)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("MILESTONES")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Spacing.xl)
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()

            if !viewModel.milestonesAchieved.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.milestonesAchieved.sorted(), id: \.self) { milestone in
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("\(milestone) days")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dsTertiaryDim.opacity(0.15))
                            .foregroundStyle(Color.dsTertiaryContainer)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeaderView("RECENT SESSIONS")

            if viewModel.recentSessions.isEmpty {
                Text("No sessions logged yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .padding()
            } else {
                ForEach(viewModel.recentSessions) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: SessionLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dsAccentOrange.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: sessionIcon(session.activityType))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsAccentOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionTypeName(session.activityType))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dsOnSurface)
                    Text(formattedDate(session.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let duration = session.duration {
                        Text("\(duration) min")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                    }
                    HStack(spacing: 6) {
                        if let effort = session.effortLevel {
                            rpeBadge(effort)
                        }
                        if let mood = session.mood {
                            Text(moodEmoji(mood))
                                .font(.system(size: 14))
                        }
                    }
                }
            }

            let highlights = viewModel.parseChips(session.win)
            if !highlights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.dsTertiaryContainer)
                        ForEach(highlights, id: \.self) { chip in
                            Text(formatAPIString(chip))
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dsTertiaryDim.opacity(0.12))
                                .foregroundStyle(Color.dsTertiaryContainer)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            let focuses = viewModel.parseChips(session.focus)
            if !focuses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.dsSecondary)
                        ForEach(focuses, id: \.self) { chip in
                            Text(formatAPIString(chip))
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.dsSecondary.opacity(0.12))
                                .foregroundStyle(Color.dsSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private func rpeBadge(_ effort: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10))
            Text("\(effort)")
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(rpeColor(effort).opacity(0.15))
        .foregroundStyle(rpeColor(effort))
        .clipShape(Capsule())
    }

    private func rpeColor(_ rpe: Int) -> Color {
        if rpe <= 3 { return Color.dsSecondary }
        if rpe <= 6 { return Color.dsAccentOrange }
        return Color.dsError
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood.uppercased() {
        case "EXCITED": return "\u{1F60A}"
        case "FOCUSED": return "\u{1F3AF}"
        case "OKAY": return "\u{1F610}"
        case "TIRED": return "\u{1F634}"
        case "STRESSED": return "\u{1F624}"
        default: return "\u{1F610}"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No Progress Yet", subtitle: "Complete training sessions to start tracking your progress and see your stats here.")
    }

    // MARK: - Helpers

    private func sessionIcon(_ type: String?) -> String {
        guard let type else { return "figure.run" }
        switch type {
        case "SELF_TRAINING": return "figure.run"
        case "COACH_1ON1": return "person.2.fill"
        case "TEAM_TRAINING": return "person.3.fill"
        case "FACILITY_CLASS": return "building.2.fill"
        case "OFFICIAL_GAME": return "sportscourt.fill"
        case "FUTSAL_GAME": return "soccerball"
        case "INDOOR_LEAGUE_GAME": return "soccerball.inverse"
        default: return "figure.run"
        }
    }

    private func sessionTypeName(_ type: String?) -> String {
        guard let type else { return "Session" }
        return ActivityType(rawValue: type)?.displayName ?? formatAPIString(type)
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else {
            return isoString
        }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView(childId: "preview-child")
    }
}
