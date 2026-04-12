import SwiftUI

struct NewActivityView: View {
    let childId: String
    @ObservedObject var viewModel: ActivityLogViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= viewModel.currentStep ? Color.dsAccentOrange : Color.dsSurfaceContainerHighest)
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // Atmospheric glow
            RadialGradient(
                colors: [
                    Color.dsAccentOrange.opacity(0.15),
                    Color.dsAccentOrange.opacity(0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 10,
                endRadius: 250
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity)

            // Content
            Group {
                switch viewModel.currentStep {
                case 0:
                    activityTypeStep
                case 1:
                    detailsStep
                case 2:
                    reflectionStep
                case 3:
                    confirmStep
                default:
                    EmptyView()
                }
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.dsError)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("New Activity")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPickers()
        }
    }

    // MARK: - Step 0: Activity Type

    private var activityTypeStep: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("What did you do?")
                    .font(.title3.bold())
                    .padding(.top, 16)

                ForEach(ActivityType.allCases, id: \.rawValue) { type in
                    Button {
                        viewModel.activityType = type.rawValue
                        viewModel.nextStep()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: activityIcon(type.rawValue))
                                .font(.title2)
                                .foregroundStyle(Color.dsAccentOrange)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            if viewModel.activityType == type.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dsAccentOrange)
                            }

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Step 1: Details

    private var detailsStep: some View {
        Form {
            Section("Duration") {
                Stepper(value: $viewModel.durationMinutes, in: 5...240, step: 5) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(viewModel.durationMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            FacilityPickerView(
                selectedFacilityId: $viewModel.selectedFacilityId,
                facilities: viewModel.facilities,
                isLoading: viewModel.isLoadingPickers,
                onCreate: viewModel.createFacility
            )

            CoachPickerView(
                selectedCoachId: $viewModel.selectedCoachId,
                coaches: viewModel.coaches,
                isLoading: viewModel.isLoadingPickers,
                onCreate: viewModel.createCoach
            )

            ProgramPickerView(
                selectedProgramId: $viewModel.selectedProgramId,
                programs: viewModel.programs,
                isLoading: viewModel.isLoadingPickers,
                onCreate: viewModel.createProgram
            )

            if viewModel.isGameType {
                Section("Opponent") {
                    TextField("Opponent team name", text: $viewModel.opponent)
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
                    .tint(Color.dsAccentOrange)
                    HStack {
                        Text("Easy").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("Max Effort").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Game IQ Impact") {
                Picker("Impact", selection: $viewModel.gameIQImpact) {
                    Text("Low").tag(GameIQImpact.low.rawValue)
                    Text("Medium").tag(GameIQImpact.medium.rawValue)
                    Text("High").tag(GameIQImpact.high.rawValue)
                }
                .pickerStyle(.segmented)
            }

            Section {
                navigationButtons
            }
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Step 2: Reflection

    private var reflectionStep: some View {
        Form {
            Section("Focus Tags") {
                if viewModel.focusTags.isEmpty && viewModel.isLoadingPickers {
                    ProgressView()
                } else {
                    ChipPickerView(
                        items: viewModel.focusTags.map { ChipItem(id: $0.id, label: $0.label) },
                        selectedIds: $viewModel.selectedFocusTags,
                        maxSelection: 3,
                        accentColor: .blue
                    )
                }
            }

            Section("Highlights") {
                if viewModel.highlightChips.isEmpty && viewModel.isLoadingPickers {
                    ProgressView()
                } else {
                    ChipPickerView(
                        items: viewModel.highlightChips.map { ChipItem(id: $0.id, label: $0.label) },
                        selectedIds: $viewModel.selectedHighlights,
                        maxSelection: 3,
                        accentColor: .green
                    )
                }
            }

            Section("Next Focus") {
                if viewModel.nextFocusChips.isEmpty && viewModel.isLoadingPickers {
                    ProgressView()
                } else {
                    ChipPickerView(
                        items: viewModel.nextFocusChips.map { ChipItem(id: $0.id, label: $0.label) },
                        selectedIds: $viewModel.selectedNextFocus,
                        maxSelection: 2,
                        accentColor: .purple
                    )
                }
            }

            Section("Notes (Optional)") {
                TextField("How did it go?", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                navigationButtons
            }
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
        Form {
            Section("Summary") {
                summaryRow("Type", ActivityType(rawValue: viewModel.activityType)?.displayName ?? viewModel.activityType)
                summaryRow("Duration", "\(viewModel.durationMinutes) min")
                summaryRow("Effort", "\(viewModel.intensityRPE) / 10")
                summaryRow("Game IQ", viewModel.gameIQImpact.capitalized)

                if let fac = viewModel.facilities.first(where: { $0.id == viewModel.selectedFacilityId }) {
                    summaryRow("Facility", fac.name)
                }
                if let coach = viewModel.coaches.first(where: { $0.id == viewModel.selectedCoachId }) {
                    summaryRow("Coach", coach.displayName)
                }
                if let prog = viewModel.programs.first(where: { $0.id == viewModel.selectedProgramId }) {
                    summaryRow("Program", prog.name)
                }
            }

            if !viewModel.selectedFocusTags.isEmpty || !viewModel.selectedHighlights.isEmpty || !viewModel.selectedNextFocus.isEmpty {
                Section("Reflection") {
                    if !viewModel.selectedFocusTags.isEmpty {
                        let labels = viewModel.focusTags.filter { viewModel.selectedFocusTags.contains($0.id) }.map(\.label)
                        summaryRow("Focus", labels.joined(separator: ", "))
                    }
                    if !viewModel.selectedHighlights.isEmpty {
                        let labels = viewModel.highlightChips.filter { viewModel.selectedHighlights.contains($0.id) }.map(\.label)
                        summaryRow("Highlights", labels.joined(separator: ", "))
                    }
                    if !viewModel.selectedNextFocus.isEmpty {
                        let labels = viewModel.nextFocusChips.filter { viewModel.selectedNextFocus.contains($0.id) }.map(\.label)
                        summaryRow("Next Focus", labels.joined(separator: ", "))
                    }
                }
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
                            ProgressView().tint(.white)
                        } else {
                            Label("Save Activity", systemImage: "checkmark.circle.fill")
                        }
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(DSGradient.orangeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Button("Back") {
                    viewModel.previousStep()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - Helpers

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep > 0 {
                Button("Back") {
                    viewModel.previousStep()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button("Next") {
                viewModel.nextStep()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(DSGradient.orangeAccent)
            .foregroundStyle(.white)
            .font(.headline)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .listRowInsets(EdgeInsets())
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
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
}

#Preview {
    NavigationStack {
        NewActivityView(
            childId: "preview-child",
            viewModel: ActivityLogViewModel(childId: "preview-child")
        )
    }
}
