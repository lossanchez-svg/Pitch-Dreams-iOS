import SwiftUI

struct SkillTrackView: View {
    let childId: String
    @StateObject private var viewModel: SkillsViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: SkillsViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if viewModel.isLoading && viewModel.drillStats.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonView(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        }
                    } else if viewModel.drillStats.isEmpty {
                        emptyState
                    } else {
                        // Atmospheric hero glow
                        heroGlow

                        // Hero summary card
                        skillsSummary

                        // Section header
                        Text("YOUR DRILLS")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Drill cards
                        ForEach(viewModel.drillStats) { stat in
                            if let drill = DrillRegistry.all.first(where: { $0.id == stat.drillKey }) {
                                NavigationLink {
                                    DrillDetailView(drill: drill, childId: childId)
                                } label: {
                                    drillCard(stat, drill: drill)
                                }
                                .buttonStyle(.plain)
                            } else {
                                drillCard(stat, drill: nil)
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.dsError)
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
                Text("SKILLS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .refreshable {
            await viewModel.loadStats()
        }
        .task {
            await viewModel.loadStats()
        }
    }

    // MARK: - Hero Glow

    private var heroGlow: some View {
        VStack(spacing: 8) {
            Text("YOUR TOOLKIT")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.dsOnSurfaceVariant)

            Text("Master each drill to level up")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(
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
        )
    }

    // MARK: - Skills Summary

    private var skillsSummary: some View {
        HStack(spacing: Spacing.lg) {
            // Total drills practiced
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dsAccentOrange)
                Text("\(viewModel.drillStats.count)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("DRILLS\nPRACTICED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()

            // Total attempts
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "repeat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dsSecondary)
                Text("\(viewModel.drillStats.map(\.totalAttempts).reduce(0, +))")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("TOTAL\nATTEMPTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()
        }
    }

    // MARK: - Drill Card

    private func drillCard(_ stat: DrillStat, drill: DrillDefinition?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dsAccentOrange.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: drillIcon(for: drill?.category))
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dsAccentOrange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(formatDrillKey(stat.drillKey))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    if let drill {
                        Text(drill.category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Color.dsSecondary)
                    }
                }

                Spacer()

                confidenceStars(stat.avgConfidence)
            }

            // Stats row
            HStack(spacing: Spacing.xl) {
                HStack(spacing: 6) {
                    Image(systemName: "repeat")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text("\(stat.totalAttempts) attempts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                if let lastAttempt = stat.lastAttempt {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                        Text(formattedDate(lastAttempt))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            // Confidence bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.dsSurfaceContainerHighest)
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.dsTertiaryDim, Color.dsTertiaryContainer],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(1.0, stat.avgConfidence / 5.0), height: 6)
                        .shadow(color: Color.dsTertiaryContainer.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 6)
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private func confidenceStars(_ avg: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starIcon(for: star, avg: avg))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsTertiaryContainer)
            }
        }
    }

    private func starIcon(for position: Int, avg: Double) -> String {
        let threshold = Double(position)
        if avg >= threshold { return "star.fill" }
        else if avg >= threshold - 0.5 { return "star.leadinghalf.filled" }
        else { return "star" }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(Color.dsSurfaceContainer)
                    .frame(width: 100, height: 100)
                Image(systemName: "star.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Text("No Drill Stats")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
            Text("Complete drills during training to see your stats here.")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer(minLength: 40)
        }
    }

    // MARK: - Helpers

    private func formatDrillKey(_ key: String) -> String {
        if let drill = DrillRegistry.all.first(where: { $0.id == key }) {
            return drill.name
        }
        return formatAPIString(key)
    }

    private func drillIcon(for category: String?) -> String {
        switch category {
        case "Ball Mastery": return "figure.soccer"
        case "Passing": return "arrow.triangle.swap"
        case "Shooting": return "scope"
        case "Dribbling": return "figure.walk"
        case "First Touch": return "hand.point.up.fill"
        default: return "target"
        }
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else {
            return isoString
        }
        let display = DateFormatter()
        display.dateStyle = .short
        return display.string(from: date)
    }
}

#Preview {
    NavigationStack {
        SkillTrackView(childId: "preview-child")
    }
}
