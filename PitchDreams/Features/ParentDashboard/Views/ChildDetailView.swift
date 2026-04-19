import SwiftUI

struct ChildDetailView: View {
    let child: ChildSummary
    @StateObject private var viewModel: ChildDetailViewModel
    @State private var showExportAlert = false
    @State private var showDeleteAlert = false
    @State private var showAvatarPicker = false
    @State private var showPinSetup = false
    @State private var selectedAvatarId: String?

    private let apiClient: APIClientProtocol = APIClient()

    init(child: ChildSummary) {
        self.child = child
        _viewModel = StateObject(wrappedValue: ChildDetailViewModel(childId: child.id))
    }

    var body: some View {
        List {
            // Profile section
            Section {
                HStack(spacing: 16) {
                    childProfileAvatar
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.nickname)
                            .font(.title2.bold())
                        Text("Age \(child.age)")
                            .foregroundStyle(.secondary)
                        if let position = child.position {
                            Text(position)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        showAvatarPicker = true
                    } label: {
                        Text("Change")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.dsSecondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Monthly overview
            Section("This Month") {
                LabeledContent("Sessions") {
                    Text("\(viewModel.monthlySessionCount)")
                        .font(.body.bold())
                }
                LabeledContent("Training Time") {
                    Text(viewModel.formattedTotalTime)
                        .font(.body.bold())
                }
                LabeledContent("Current Streak") {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(viewModel.currentStreak) days")
                            .font(.body.bold())
                    }
                }
                LabeledContent("Avg Intensity") {
                    Text(viewModel.avgRPE > 0 ? String(format: "%.1f / 10", viewModel.avgRPE) : "N/A")
                        .font(.body.bold())
                }
                LabeledContent("Avg Game IQ") {
                    Text(viewModel.avgGameIQLabel)
                        .font(.body.bold())
                        .foregroundStyle(gameIQColor(viewModel.avgGameIQLabel))
                }
            }

            // Activity Breakdown
            if !viewModel.activityBreakdown.isEmpty {
                Section("Activity Breakdown") {
                    ForEach(viewModel.activityBreakdown, id: \.type) { item in
                        HStack {
                            Image(systemName: activityIcon(item.type))
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            Text(ActivityType(rawValue: item.type)?.displayName ?? item.type)
                                .font(.subheadline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.count) sessions")
                                    .font(.caption.weight(.semibold))
                                Text("\(item.minutes) min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Streak section
            if let streak = viewModel.streakData {
                Section("Streaks") {
                    LabeledContent("Freezes Available", value: "\(streak.freezes)")
                    LabeledContent("Freezes Used", value: "\(streak.freezesUsed)")
                    if !streak.milestones.isEmpty {
                        LabeledContent("Milestones") {
                            Text(streak.milestones.sorted().map { "\($0)d" }.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Login & Security
            Section("Login & Security") {
                Button {
                    showPinSetup = true
                } label: {
                    Label("Set / Reset PIN", systemImage: "lock.shield")
                }
            }

            // Premium parent surfaces. Free-tier parents see a locked
            // preview via `.gated(by:)`, which presents the paywall on tap.
            Section("Premium") {
                NavigationLink {
                    AdvancedAnalyticsView(childId: child.id, childName: child.nickname)
                        .gated(by: .advancedAnalytics, context: .advancedAnalytics)
                } label: {
                    premiumRow(label: "Trends & Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink {
                    DevelopmentProfileExportView(child: child)
                        .gated(by: .developmentProfilePDF, context: .developmentReport)
                } label: {
                    premiumRow(label: "Development Profile PDF", systemImage: "doc.richtext")
                }

                NavigationLink {
                    WeeklyInsightsEmailSettingsView(child: child)
                        .gated(by: .parentWeeklyInsightsEmail, context: .settingsBrowse)
                } label: {
                    premiumRow(label: "Weekly Insights Email", systemImage: "envelope.fill")
                }

                NavigationLink {
                    FullSessionHistoryView(childId: child.id, childName: child.nickname)
                        .gated(by: .unlimitedHistory, context: .historyHorizon)
                } label: {
                    premiumRow(label: "Full Training History", systemImage: "clock.arrow.circlepath")
                }

                NavigationLink {
                    PrioritySupportView(child: child)
                        .gated(by: .prioritySupport, context: .settingsBrowse)
                } label: {
                    premiumRow(label: "Priority Support", systemImage: "star.fill")
                }
            }

            // Actions section
            Section("Actions") {
                NavigationLink {
                    ParentControlsView(childId: child.id, childName: child.nickname)
                } label: {
                    Label("Permissions & Controls", systemImage: "gearshape")
                }

                Button {
                    showExportAlert = true
                } label: {
                    Label("Export Training Data", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            }
        }
        .navigationTitle(child.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.sessions.isEmpty {
                ProgressView()
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Export Data", isPresented: $showExportAlert) {
            Button("Export") { Task { await exportData() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Download \(child.nickname)'s training data as JSON?")
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarChangeSheet(childId: child.id) {
                showAvatarPicker = false
            }
        }
        .sheet(isPresented: $showPinSetup) {
            PinSetupSheet(childId: child.id, childName: child.nickname)
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(child.nickname)'s account and all training data. This cannot be undone.")
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var childProfileAvatar: some View {
        let assetName = Avatar.assetName(for: child.avatarId, totalXP: 0)
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "figure.soccer")
                .font(.largeTitle)
                .foregroundStyle(Color.dsSecondary)
                .frame(width: 60, height: 60)
                .background(Color.dsSecondary.opacity(0.12))
        }
    }

    // MARK: - Premium row helper

    private func premiumRow(label: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Label(label, systemImage: systemImage)
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Color.dsAccentOrange)
        }
    }

    // MARK: - Helpers

    private func gameIQColor(_ label: String) -> Color {
        switch label {
        case "High": return .green
        case "Medium": return .orange
        case "Low": return .red
        default: return .secondary
        }
    }

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

    private func exportData() async {
        let _: ExportResponse? = try? await apiClient.request(APIRouter.exportChildData(childId: child.id))
    }

    private func deleteAccount() async {
        try? await apiClient.requestVoid(APIRouter.deleteChild(childId: child.id))
    }
}

struct ExportResponse: Codable {
    let child: ExportChild
    let sessions: [ExportSession]
    let exportedAt: String
}

struct ExportChild: Codable {
    let nickname: String
    let age: Int
    let position: String?
    let createdAt: String
}

struct ExportSession: Codable {
    let activityType: String?
    let effortLevel: Int?
    let mood: String?
    let duration: Int?
}

#Preview {
    NavigationStack {
        ChildDetailView(child: ChildSummary(id: "1", nickname: "Jude", age: 9, position: "Midfielder", avatarId: nil))
    }
}
