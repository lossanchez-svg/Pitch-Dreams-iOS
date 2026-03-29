import SwiftUI

struct ProgressDashboardView: View {
    let childId: String
    @StateObject private var viewModel: ProgressViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ProgressViewModel(childId: childId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    Spacer(minLength: 100)
                    ProgressView("Loading progress...")
                    Spacer(minLength: 100)
                } else if viewModel.sessions.isEmpty && viewModel.streakData == nil {
                    emptyState
                } else {
                    statsGrid
                    streakSection
                    recentSessionsSection
                }

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCard(
                title: "Current Streak",
                value: "\(viewModel.currentStreak)",
                unit: "days",
                icon: "flame.fill",
                color: .orange
            )
            statCard(
                title: "Total Sessions",
                value: "\(viewModel.totalSessions)",
                unit: "sessions",
                icon: "figure.run",
                color: .blue
            )
            statCard(
                title: "Training Time",
                value: formattedTime(viewModel.totalMinutes),
                unit: "",
                icon: "clock.fill",
                color: .green
            )
            statCard(
                title: "Avg Intensity",
                value: String(format: "%.1f", viewModel.averageEffort),
                unit: "/ 10",
                icon: "bolt.fill",
                color: .purple
            )
        }
    }

    private func statCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Details")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                    Text("\(viewModel.freezesAvailable)")
                        .font(.title3.bold())
                    Text("Freezes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 50)

                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                    Text("\(viewModel.milestonesAchieved.count)")
                        .font(.title3.bold())
                    Text("Milestones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if !viewModel.milestonesAchieved.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.milestonesAchieved.sorted(), id: \.self) { milestone in
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("\(milestone) days")
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.yellow.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            if viewModel.recentSessions.isEmpty {
                Text("No sessions logged yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentSessions) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: SessionLog) -> some View {
        HStack {
            Image(systemName: sessionIcon(session.activityType))
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(sessionTypeName(session.activityType))
                    .font(.subheadline.weight(.medium))
                Text(formattedDate(session.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let duration = session.duration {
                    Text("\(duration) min")
                        .font(.subheadline.weight(.semibold))
                }
                if let effort = session.effortLevel {
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                        Text("\(effort)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Progress Yet")
                .font(.title3.bold())
            Text("Complete training sessions to start tracking your progress and see your stats here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func formattedTime(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

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
        return ActivityType(rawValue: type)?.displayName ?? type.capitalized
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
