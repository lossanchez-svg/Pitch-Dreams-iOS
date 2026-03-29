import SwiftUI

struct ChildDetailView: View {
    let child: ChildSummary
    @State private var streakData: StreakData?
    @State private var isLoading = true
    @State private var showExportAlert = false
    @State private var showDeleteAlert = false

    private let apiClient: APIClientProtocol = APIClient()

    var body: some View {
        List {
            // Profile section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "figure.soccer")
                        .font(.largeTitle)
                        .foregroundStyle(.cyan)
                        .frame(width: 60, height: 60)
                        .background(.cyan.opacity(0.12))
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
                }
                .padding(.vertical, 8)
            }

            // Streak section
            if let streak = streakData {
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
        .task {
            await loadData()
        }
        .alert("Export Data", isPresented: $showExportAlert) {
            Button("Export") { Task { await exportData() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Download \(child.nickname)'s training data as JSON?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(child.nickname)'s account and all training data. This cannot be undone.")
        }
    }

    private func loadData() async {
        isLoading = true
        streakData = try? await apiClient.request(APIRouter.getStreaks(childId: child.id))
        isLoading = false
    }

    private func exportData() async {
        // TODO: Handle export response (download/share JSON)
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
        ChildDetailView(child: ChildSummary(id: "1", nickname: "Jude", age: 9, position: "Midfielder"))
    }
}
