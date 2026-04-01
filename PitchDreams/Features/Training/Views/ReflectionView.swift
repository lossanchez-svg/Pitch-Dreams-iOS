import SwiftUI

struct ReflectionView: View {
    @ObservedObject var viewModel: ActiveTrainingViewModel
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var reflectionStep = 0
    @State private var lastVoiceCommand: String?

    private let moodOptions: [(name: String, emoji: String, label: String)] = [
        ("GREAT", "😄", "Great"),
        ("GOOD", "😊", "Good"),
        ("OKAY", "😐", "Okay"),
        ("TIRED", "😴", "Tired"),
        ("OFF", "😞", "Off"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Step indicator
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index <= reflectionStep ? Color.orange : Color(.systemGray4))
                            .frame(height: 3)
                    }
                }

                Text(reflectionTitle)
                    .font(.title3.bold())

                // Content for each step
                switch reflectionStep {
                case 0:
                    rpeStep
                case 1:
                    highlightStep
                case 2:
                    nextFocusStep
                case 3:
                    moodStep
                default:
                    EmptyView()
                }

                // Navigation
                HStack(spacing: 16) {
                    if reflectionStep > 0 {
                        Button {
                            reflectionStep -= 1
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        if reflectionStep < 3 {
                            reflectionStep += 1
                        } else {
                            Task { await viewModel.saveSession() }
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(reflectionStep < 3 ? "Next" : "Save Session")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading)
                }

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            processReflectionVoiceCommand(newTranscript)
        }
    }

    // MARK: - Voice Commands

    private func processReflectionVoiceCommand(_ transcript: String) {
        let lower = transcript.lowercased()

        // "next" / "continue" → advance step
        if lower.contains("next") || lower.contains("continue") {
            if reflectionStep < 3 {
                reflectionStep += 1
                lastVoiceCommand = "Next"
                return
            }
        }

        // "back" / "previous" → go back
        if lower.contains("back") || lower.contains("previous") {
            if reflectionStep > 0 {
                reflectionStep -= 1
                lastVoiceCommand = "Back"
                return
            }
        }

        // "save" / "done" / "finish" → save session (only on last step)
        if lower.contains("save") || lower.contains("done") || lower.contains("finish") {
            if reflectionStep == 3 {
                Task { await viewModel.saveSession() }
                lastVoiceCommand = "Save"
                return
            } else {
                // Auto-advance to save
                reflectionStep = 3
                lastVoiceCommand = "Skip to Save"
                return
            }
        }

        // On RPE step: numbers set the slider
        if reflectionStep == 0 {
            if let number = VoiceCommandMatcher.extractNumber(from: transcript), number >= 1, number <= 10 {
                viewModel.reflectionRPE = number
                lastVoiceCommand = "RPE: \(number)"
                return
            }
        }

        // On mood step: mood names select the mood
        if reflectionStep == 3 {
            for mood in moodOptions {
                if lower.contains(mood.label.lowercased()) || lower.contains(mood.name.lowercased()) {
                    viewModel.reflectionMood = mood.name.lowercased()
                    lastVoiceCommand = mood.label
                    return
                }
            }
        }
    }

    // MARK: - Steps

    private var rpeStep: some View {
        VStack(spacing: 16) {
            Text(rpeEmoji)
                .font(.system(size: 48))
            Text("\(viewModel.reflectionRPE) / 10")
                .font(.title.bold())
            Slider(
                value: Binding(
                    get: { Double(viewModel.reflectionRPE) },
                    set: { viewModel.reflectionRPE = Int($0) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(.orange)
            HStack {
                Text("Easy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Maximum")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var highlightStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What went well? (up to 3)")
                .font(.subheadline.weight(.medium))

            if viewModel.highlightOptions.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                ChipPickerView(
                    items: viewModel.highlightOptions.map { ChipItem(id: $0.id, label: $0.label) },
                    selectedIds: $viewModel.selectedHighlights,
                    maxSelection: 3,
                    accentColor: .green
                )
            }
        }
    }

    private var nextFocusStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What to work on next? (up to 2)")
                .font(.subheadline.weight(.medium))

            if viewModel.nextFocusOptions.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                ChipPickerView(
                    items: viewModel.nextFocusOptions.map { ChipItem(id: $0.id, label: $0.label) },
                    selectedIds: $viewModel.selectedNextFocus,
                    maxSelection: 2,
                    accentColor: .blue
                )
            }
        }
    }

    private var moodStep: some View {
        VStack(spacing: 16) {
            Text("How do you feel after training?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(moodOptions, id: \.name) { mood in
                    let isSelected = viewModel.reflectionMood == mood.name.lowercased()
                    Button {
                        viewModel.reflectionMood = mood.name.lowercased()
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 32))
                            Text(mood.label)
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .orange : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? .orange.opacity(0.12) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private var reflectionTitle: String {
        switch reflectionStep {
        case 0: return "How hard was that?"
        case 1: return "Highlights"
        case 2: return "Next Focus"
        case 3: return "Mood"
        default: return ""
        }
    }

    private var rpeEmoji: String {
        switch viewModel.reflectionRPE {
        case 1...3: return "😌"
        case 4...6: return "😤"
        case 7...8: return "💪"
        case 9...10: return "🔥"
        default: return "😤"
        }
    }
}
