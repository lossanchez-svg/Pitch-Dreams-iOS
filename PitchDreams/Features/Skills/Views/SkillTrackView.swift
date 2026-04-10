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
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading && viewModel.drillStats.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 12) {
                                SkeletonView(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 6) {
                                    SkeletonView(width: 140, height: 14)
                                    SkeletonView(width: 100, height: 10)
                                }
                                Spacer()
                                SkeletonView(width: 70, height: 12)
                            }
                            .padding(Spacing.lg)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        }
                    } else if viewModel.drillStats.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                            Text("No Drill Stats")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.dsOnSurface)
                            Text("Complete drills during training to see your stats here.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 60)
                    } else {
                        Text("YOUR DRILLS")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(viewModel.drillStats) { stat in
                            if let drill = DrillRegistry.all.first(where: { $0.id == stat.drillKey }) {
                                NavigationLink {
                                    DrillDetailView(drill: drill, childId: childId)
                                } label: {
                                    drillRow(stat)
                                }
                                .buttonStyle(.plain)
                            } else {
                                drillRow(stat)
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

    private func drillRow(_ stat: DrillStat) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dsAccentOrange.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "target")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dsAccentOrange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(formatDrillKey(stat.drillKey))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.dsOnSurface)
                HStack(spacing: 10) {
                    Label("\(stat.totalAttempts)", systemImage: "repeat")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    if let lastAttempt = stat.lastAttempt {
                        Text(formattedDate(lastAttempt))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
            }

            Spacer()

            confidenceStars(stat.avgConfidence)
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
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

    private func formatDrillKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
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
