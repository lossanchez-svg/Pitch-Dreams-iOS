import SwiftUI

struct SkillTrackView: View {
    let childId: String
    @StateObject private var viewModel: SkillsViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: SkillsViewModel(childId: childId))
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.drillStats.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            } else if viewModel.drillStats.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Drill Stats")
                            .font(.headline)
                        Text("Complete drills during training to see your stats here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section("Your Drills") {
                    ForEach(viewModel.drillStats) { stat in
                        drillRow(stat)
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
        .navigationTitle("Skills")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadStats()
        }
        .task {
            await viewModel.loadStats()
        }
    }

    // MARK: - Drill Row

    private func drillRow(_ stat: DrillStat) -> some View {
        HStack {
            Image(systemName: "target")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(formatDrillKey(stat.drillKey))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 12) {
                    Label("\(stat.totalAttempts)", systemImage: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let lastAttempt = stat.lastAttempt {
                        Text(formattedDate(lastAttempt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            confidenceStars(stat.avgConfidence)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Confidence Stars

    private func confidenceStars(_ avg: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starIcon(for: star, avg: avg))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func starIcon(for position: Int, avg: Double) -> String {
        let threshold = Double(position)
        if avg >= threshold {
            return "star.fill"
        } else if avg >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }

    // MARK: - Helpers

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
