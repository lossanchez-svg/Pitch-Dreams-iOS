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
            Form {
                Section("Energy Level") {
                    Stepper(value: $energy, in: 1...5) {
                        HStack {
                            Text("Energy")
                            Spacer()
                            Text("\(energy) / 5")
                                .foregroundStyle(.secondary)
                        }
                    }
                    energyBar
                }

                Section("Soreness") {
                    Picker("Soreness", selection: $soreness) {
                        ForEach(Soreness.allCases, id: \.self) { level in
                            Text(sorenessLabel(level)).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Focus Level") {
                    Stepper(value: $focus, in: 1...5) {
                        HStack {
                            Text("Focus")
                            Spacer()
                            Text("\(focus) / 5")
                                .foregroundStyle(.secondary)
                        }
                    }
                    focusBar
                }

                Section("Mood") {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(MoodEmoji.allCases, id: \.self) { mood in
                            Text(moodDisplayLabel(mood)).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Time Available") {
                    Picker("Minutes", selection: $timeAvail) {
                        ForEach(timeOptions, id: \.self) { mins in
                            Text("\(mins) min").tag(mins)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle(isOn: $painFlag) {
                        Label("Any pain or discomfort?", systemImage: "exclamationmark.triangle")
                    }
                } footer: {
                    if painFlag {
                        Text("Your session will be adjusted for recovery. Listen to your body.")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
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
                            Spacer()
                            if viewModel.isCheckingIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label("Submit Check-In", systemImage: "checkmark.circle.fill")
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
                    .disabled(viewModel.isCheckingIn)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Full Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    // MARK: - Subviews

    private var energyBar: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(level <= energy ? .orange : .gray.opacity(0.2))
                    .frame(height: 8)
            }
        }
    }

    private var focusBar: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(level <= focus ? .blue : .gray.opacity(0.2))
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
        case .excited: return "😄"
        case .focused: return "🎯"
        case .okay: return "😊"
        case .tired: return "😴"
        case .stressed: return "😰"
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
