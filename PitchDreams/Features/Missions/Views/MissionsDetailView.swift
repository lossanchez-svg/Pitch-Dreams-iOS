import SwiftUI

struct MissionsDetailView: View {
    let childId: String
    @ObservedObject private var viewModel = MissionsViewModel.shared

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("THIS WEEK")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(Color.dsSecondary)

                        Text("Resets in \(viewModel.daysUntilReset()) day\(viewModel.daysUntilReset() == 1 ? "" : "s") \(timeRemaining)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // XP earned banner
                    xpBanner
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Mission cards
                    VStack(spacing: 16) {
                        ForEach(viewModel.weeklyMissions) { instance in
                            missionCard(instance)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Grand Reward
                    grandRewardCard
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .task { viewModel.load(childId: childId) }
    }

    // MARK: - XP Banner

    private var xpBanner: some View {
        HStack(spacing: 16) {
            // XP amount
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(earnedXP)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsTertiaryContainer)
                    Text("XP")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dsTertiaryDim)
                }
                Text("EARNED")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Spacer()

            // Completion badge
            VStack(spacing: 4) {
                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dsSecondary)
                Text("MISSIONS\nCOMPLETE")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(Color.dsSurfaceContainerHigh)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.dsSecondary.opacity(0.3), lineWidth: 2)
            )
        }
        .padding(20)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Mission Card

    private func missionCard(_ instance: MissionInstance) -> some View {
        let isComplete = instance.isCompleted
        let isLocked = false // All missions available in v1

        return HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isComplete ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHigh)
                    .frame(width: 48, height: 48)

                Image(systemName: instance.mission.iconSystemName)
                    .font(.system(size: 20))
                    .foregroundStyle(isComplete ? Color.dsSecondary : Color.dsAccentOrange)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(instance.mission.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.dsOnSurface)

                    Spacer()

                    // Progress fraction
                    Text("\(instance.progress)/\(instance.mission.targetCount)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(isComplete ? Color.dsSecondary : Color.dsOnSurface)
                }

                Text(instance.mission.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineLimit(2)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.dsSurfaceContainerHighest)
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                isComplete
                                    ? LinearGradient(colors: [.dsSecondary, Color(hex: "#34D9EC")], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.dsAccentOrange, Color(hex: "#9D3500")], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * instance.progressFraction, height: 6)
                            .shadow(color: (isComplete ? Color.dsSecondary : Color.dsAccentOrange).opacity(0.4), radius: 4)
                    }
                }
                .frame(height: 6)

                // XP reward pill
                HStack(spacing: 4) {
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsSecondary)
                    }
                    Text("+\(instance.mission.xpReward) XP")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isComplete ? Color.dsSecondary : Color.dsTertiaryDim)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isComplete ? Color.dsSecondary.opacity(0.1) : Color.dsTertiaryDim.opacity(0.1)
                )
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    isComplete ? Color.dsSecondary.opacity(0.2) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Grand Reward

    private var grandRewardCard: some View {
        VStack(spacing: 16) {
            Text("GRAND REWARD")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.dsTertiaryContainer)

            // Mystery card
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [Color.dsTertiaryDim.opacity(0.2), Color.dsTertiaryContainer.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)

                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.dsTertiaryContainer)

                        Text("Legendary\nMoment Card")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.dsOnSurface)
                    }
                }

                Text("Complete all 3 missions to unlock a piece of football history")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)

                if allComplete {
                    Text("FINAL STAGE\nPLAYER")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsTertiaryContainer)
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(completedCount) OF \(totalCount) COMPLETE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .padding(24)
            .background(Color.dsSurfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xxl)
                    .stroke(Color.dsTertiaryContainer.opacity(0.2), lineWidth: 1)
            )
            .dsTertiaryShadow()
        }
    }

    // MARK: - Helpers

    private var earnedXP: Int {
        viewModel.weeklyMissions
            .filter(\.isCompleted)
            .map(\.mission.xpReward)
            .reduce(0, +)
    }

    private var completedCount: Int {
        viewModel.weeklyMissions.filter(\.isCompleted).count
    }

    private var totalCount: Int {
        max(viewModel.weeklyMissions.count, 3)
    }

    private var allComplete: Bool {
        completedCount >= totalCount && totalCount > 0
    }

    private var timeRemaining: String {
        let days = viewModel.daysUntilReset()
        let hours = 14 // Approximate — resets Monday
        return "\(days)d \(hours)h"
    }
}

#Preview {
    NavigationStack {
        MissionsDetailView(childId: "preview-child")
    }
}
