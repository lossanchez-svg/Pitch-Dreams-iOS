import SwiftUI

struct ActivityLogView: View {
    let childId: String
    @StateObject private var viewModel: ActivityLogViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ActivityLogViewModel(childId: childId))
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    NewActivityView(childId: childId, viewModel: viewModel)
                } label: {
                    Label("Log New Activity", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }

            Section("Recent Activities") {
                if viewModel.isLoading && viewModel.recentActivities.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if viewModel.recentActivities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Activities Yet")
                            .font(.headline)
                        Text("Log your first training session to start tracking progress.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.recentActivities) { activity in
                        activityRow(activity)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Activity Log")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadRecent()
        }
        .task {
            await viewModel.loadRecent()
        }
    }

    // MARK: - Activity Row

    private func activityRow(_ activity: ActivityItem) -> some View {
        HStack {
            Image(systemName: activityIcon(activity.activityType))
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(activityDisplayName(activity.activityType))
                    .font(.subheadline.weight(.medium))
                Text(formattedDate(activity.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(activity.durationMinutes) min")
                    .font(.subheadline.weight(.semibold))
                if let impact = activity.gameIQImpact {
                    Text(impact.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
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
