import SwiftUI

/// Home-screen card listing this week's 3 missions. Tap any mission → detail view.
struct MissionsCard: View {
    let childId: String
    @ObservedObject private var viewModel = MissionsViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Weekly Missions", systemImage: "target")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    MissionsDetailView(childId: childId)
                } label: {
                    Text("See all")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dsSecondary)
                }
            }

            if viewModel.weeklyMissions.isEmpty {
                Text("Loading missions…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 10) {
                    ForEach(viewModel.weeklyMissions) { instance in
                        NavigationLink {
                            MissionsDetailView(childId: childId)
                        } label: {
                            miniCard(instance)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Resets in \(viewModel.daysUntilReset()) day\(viewModel.daysUntilReset() == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .task { viewModel.load(childId: childId) }
    }

    private func miniCard(_ instance: MissionInstance) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: instance.mission.iconSystemName)
                    .font(.title3)
                    .foregroundStyle(instance.isCompleted ? .green : .orange)
                Spacer()
                if instance.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            Text(instance.mission.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            ProgressView(value: instance.progressFraction)
                .tint(instance.isCompleted ? .green : .orange)
            Text("\(instance.progress)/\(instance.mission.targetCount)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

#Preview {
    NavigationStack {
        MissionsCard(childId: "preview-child")
            .padding()
    }
}
