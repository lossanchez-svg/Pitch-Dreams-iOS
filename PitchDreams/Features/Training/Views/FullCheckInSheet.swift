import SwiftUI

struct FullCheckInSheet: View {
    let childId: String
    @ObservedObject var viewModel: TrainingViewModel
    @Binding var isPresented: Bool

    @State private var energy: Int = 3
    @State private var soreness: Soreness = .none
    @State private var focus: Int = 3
    @State private var selectedMood: MoodEmoji = .okay
    @State private var timeAvail: Int = 20
    @State private var painFlag = false

    private let timeOptions = [10, 20, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Energy
                        sectionCard(title: "ENERGY LEVEL") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Energy")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.dsOnSurface)
                                    Spacer()
                                    Text("\(energy) / 5")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.dsOnSurfaceVariant)
                                }

                                Stepper(value: $energy, in: 1...5) {
                                    EmptyView()
                                }
                                .tint(Color.dsAccentOrange)

                                levelBar(value: energy, max: 5, color: Color.dsAccentOrange)
                            }
                        }

                        // Soreness
                        sectionCard(title: "SORENESS") {
                            HStack(spacing: 8) {
                                ForEach(Soreness.allCases, id: \.self) { level in
                                    Button {
                                        soreness = level
                                    } label: {
                                        Text(sorenessLabel(level))
                                            .font(.system(size: 12, weight: .bold))
                                            .tracking(0.5)
                                            .foregroundStyle(soreness == level ? Color.dsSecondary : Color.dsOnSurfaceVariant)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(soreness == level ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    soreness == level ? Color.dsSecondary.opacity(0.3) : .clear,
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Focus
                        sectionCard(title: "FOCUS LEVEL") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Focus")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.dsOnSurface)
                                    Spacer()
                                    Text("\(focus) / 5")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.dsOnSurfaceVariant)
                                }

                                Stepper(value: $focus, in: 1...5) {
                                    EmptyView()
                                }
                                .tint(Color.dsSecondary)

                                levelBar(value: focus, max: 5, color: Color.dsSecondary)
                            }
                        }

                        // Mood
                        sectionCard(title: "MOOD") {
                            HStack(spacing: 8) {
                                ForEach(MoodEmoji.allCases, id: \.self) { mood in
                                    Button {
                                        selectedMood = mood
                                    } label: {
                                        Text(moodDisplayLabel(mood))
                                            .font(.system(size: 24))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedMood == mood ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12).stroke(
                                                    selectedMood == mood ? Color.dsSecondary.opacity(0.3) : .clear,
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Time
                        sectionCard(title: "TIME AVAILABLE") {
                            HStack(spacing: 8) {
                                ForEach(timeOptions, id: \.self) { mins in
                                    Button {
                                        timeAvail = mins
                                    } label: {
                                        Text("\(mins) MIN")
                                            .font(.system(size: 13, weight: .bold))
                                            .tracking(1)
                                            .foregroundStyle(timeAvail == mins ? Color.dsSecondary : Color.dsOnSurfaceVariant)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(timeAvail == mins ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    timeAvail == mins ? Color.dsSecondary.opacity(0.3) : .clear,
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Pain toggle
                        sectionCard(title: "PAIN CHECK") {
                            VStack(spacing: 8) {
                                Toggle(isOn: $painFlag) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(painFlag ? Color.dsAccentOrange : Color.dsOnSurfaceVariant)
                                        Text("Any pain or discomfort?")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.dsOnSurface)
                                    }
                                }
                                .tint(Color.dsAccentOrange)

                                if painFlag {
                                    Text("Your session will be adjusted for recovery. Listen to your body.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.dsAccentOrange)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // Submit
                        Button {
                            Task {
                                await viewModel.fullCheckIn(
                                    energy: energy,
                                    soreness: soreness.rawValue,
                                    focus: focus,
                                    mood: selectedMood.rawValue,
                                    timeAvail: timeAvail,
                                    painFlag: painFlag
                                )
                                if viewModel.checkInState != nil {
                                    isPresented = false
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isCheckingIn {
                                    ProgressView()
                                        .tint(Color(hex: "#5B1B00"))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("SUBMIT CHECK-IN")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .tracking(2)
                                }
                            }
                            .foregroundStyle(Color(hex: "#5B1B00"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(DSGradient.primaryCTA)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isCheckingIn)

                        if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dsError)
                        }
                    }
                    .padding(Spacing.xl)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Full Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dsBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
        }
    }

    // MARK: - Components

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)

            content()
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private func levelBar(value: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(1...max, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(level <= value ? color : Color.dsSurfaceContainerHighest)
                    .frame(height: 8)
            }
        }
    }

    // MARK: - Helpers

    private func sorenessLabel(_ soreness: Soreness) -> String {
        switch soreness {
        case .none: return "None"
        case .light: return "Light"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    private func moodDisplayLabel(_ mood: MoodEmoji) -> String {
        switch mood {
        case .excited: return "\u{1F604}"
        case .focused: return "\u{1F3AF}"
        case .okay: return "\u{1F60A}"
        case .tired: return "\u{1F634}"
        case .stressed: return "\u{1F630}"
        }
    }
}

#Preview {
    FullCheckInSheet(
        childId: "preview-child",
        viewModel: TrainingViewModel(childId: "preview-child"),
        isPresented: .constant(true)
    )
}
