import SwiftUI

struct ActivityLogView: View {
    let childId: String
    @StateObject private var viewModel: ActivityLogViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ActivityLogViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Log New Activity CTA
                    NavigationLink {
                        NewActivityView(childId: childId, viewModel: viewModel)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("LOG NEW ACTIVITY")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2)
                        }
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                    }

                    // Section header
                    Text("RECENT ACTIVITIES")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    if viewModel.isLoading && viewModel.recentActivities.isEmpty {
                        VStack {
                            ProgressView()
                                .tint(Color.dsSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if viewModel.recentActivities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.run.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                            Text("No activities yet")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.dsOnSurface)
                            Text("Log your first training session to start tracking progress.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.recentActivities) { activity in
                            activityRow(activity)
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
                Text("ACTIVITY LOG")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .refreshable {
            await viewModel.loadRecent()
        }
        .task {
            await viewModel.loadRecent()
        }
    }

    private func activityRow(_ activity: ActivityItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dsAccentOrange.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: activityIcon(activity.activityType))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dsAccentOrange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(activityDisplayName(activity.activityType))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.dsOnSurface)
                Text(formattedDate(activity.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(activity.durationMinutes) min")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                if let impact = activity.gameIQImpact {
                    Text(impact.capitalized)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Helpers

    private func activityIcon(_ type: String) -> String {
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

    private func activityDisplayName(_ type: String) -> String {
        ActivityType(rawValue: type)?.displayName ?? type
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
        ActivityLogView(childId: "preview-child")
    }
}
