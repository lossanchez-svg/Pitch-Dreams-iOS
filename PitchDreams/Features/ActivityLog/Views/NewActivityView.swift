import SwiftUI

struct NewActivityView: View {
    let childId: String
    @ObservedObject var viewModel: ActivityLogViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Activity Type") {
                Picker("Type", selection: $viewModel.activityType) {
                    ForEach(ActivityType.allCases, id: \.rawValue) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Duration") {
                Stepper(value: $viewModel.durationMinutes, in: 5...120, step: 5) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(viewModel.durationMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Intensity (RPE)") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Effort")
                        Spacer()
                        Text("\(viewModel.intensityRPE) / 10")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.intensityRPE) },
                            set: { viewModel.intensityRPE = Int($0) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                    .tint(.orange)

                    HStack {
                        Text("Easy")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Max Effort")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Game IQ Impact") {
                Picker("Impact", selection: $viewModel.gameIQImpact) {
                    ForEach(GameIQImpact.allCases, id: \.rawValue) { impact in
                        Text(impactLabel(impact)).tag(impact.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Notes (Optional)") {
                TextField("How did it go?", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    Task {
                        await viewModel.saveActivity()
                        if viewModel.saveSuccess {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Save Activity", systemImage: "checkmark.circle.fill")
                        }
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.orange.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("New Activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func impactLabel(_ impact: GameIQImpact) -> String {
        switch impact {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

#Preview {
    NavigationStack {
        NewActivityView(
            childId: "preview-child",
            viewModel: ActivityLogViewModel(childId: "preview-child")
        )
    }
}
