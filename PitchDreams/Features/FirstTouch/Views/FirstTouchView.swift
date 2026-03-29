import SwiftUI

struct FirstTouchView: View {
    let childId: String
    @StateObject private var viewModel: FirstTouchViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: FirstTouchViewModel(childId: childId))
    }

    var body: some View {
        Group {
            if viewModel.activeDrillKey != nil {
                activeDrillView
            } else {
                drillSelectionView
            }
        }
        .navigationTitle("First Touch")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadStats()
        }
    }

    // MARK: - Drill Selection

    private var drillSelectionView: some View {
        List {
            // Personal bests
            if viewModel.jugglingBest > 0 || viewModel.wallBallBest > 0 {
                Section("Personal Bests") {
                    if viewModel.jugglingBest > 0 {
                        LabeledContent("Juggling Best") {
                            Text("\(viewModel.jugglingBest) reps")
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                    }
                    if viewModel.wallBallBest > 0 {
                        LabeledContent("Wall Ball Best") {
                            Text("\(viewModel.wallBallBest) reps")
                                .fontWeight(.bold)
                                .foregroundStyle(.cyan)
                        }
                    }
                }
            }

            // Juggling drills
            Section("Juggling") {
                ForEach(FirstTouchViewModel.jugglingDrills, id: \.0) { key, name in
                    drillButton(key: key, name: name, icon: "soccerball", color: .orange)
                }
            }

            // Wall ball drills
            Section("Wall Ball") {
                ForEach(FirstTouchViewModel.wallBallDrills, id: \.0) { key, name in
                    drillButton(key: key, name: name, icon: "rectangle.portrait.and.arrow.right", color: .cyan)
                }
            }

            // History
            if !viewModel.drillStats.isEmpty {
                Section("Recent Stats") {
                    ForEach(viewModel.drillStats.prefix(5)) { stat in
                        HStack {
                            Text(stat.drillKey.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline)
                            Spacer()
                            Text("\(stat.totalAttempts) attempts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadStats()
        }
        .overlay {
            if viewModel.isLoading && viewModel.drillStats.isEmpty {
                ProgressView()
            }
        }
    }

    private func drillButton(key: String, name: String, icon: String, color: Color) -> some View {
        Button {
            viewModel.startDrill(key)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if let stat = viewModel.drillStats.first(where: { $0.drillKey == key }) {
                        Text("Best: \(stat.totalAttempts) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(color)
            }
        }
    }

    // MARK: - Active Drill

    private var activeDrillView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(viewModel.activeDrillKey?.replacingOccurrences(of: "_", with: " ").capitalized ?? "")
                .font(.title2.weight(.semibold))

            // Big counter
            Text("\(viewModel.activeCount)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
                .contentTransition(.numericText())

            // Tap button
            Button {
                withAnimation(.spring(response: 0.2)) {
                    viewModel.incrementCount()
                }
            } label: {
                Text("TAP")
                    .font(.title.bold())
                    .frame(width: 160, height: 160)
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }

            Spacer()

            // Action buttons
            HStack(spacing: 24) {
                Button {
                    viewModel.cancelDrill()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task { await viewModel.saveDrill() }
                } label: {
                    Text(viewModel.saveSuccess ? "Saved!" : "Save \(viewModel.activeCount) reps")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.activeCount == 0 || viewModel.isSaving)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    NavigationStack {
        FirstTouchView(childId: "preview-child")
    }
}
