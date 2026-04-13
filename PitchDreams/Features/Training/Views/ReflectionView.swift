import SwiftUI

struct ReflectionView: View {
    @ObservedObject var viewModel: ActiveTrainingViewModel
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var reflectionStep = 0
    @State private var lastVoiceCommand: String?
    /// Transcripts arriving before this date are discarded (coach voice protection).
    @State private var ignoreTranscriptsUntil: Date = .distantPast

    private let moodOptions: [(name: String, emoji: String, label: String)] = [
        ("GREAT", "\u{1F604}", "Great"),
        ("GOOD", "\u{1F60A}", "Good"),
        ("OKAY", "\u{1F610}", "Okay"),
        ("TIRED", "\u{1F634}", "Tired"),
        ("OFF", "\u{1F61E}", "Off"),
    ]

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Step indicator
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(index <= reflectionStep ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                                .frame(height: 4)
                        }
                    }

                    Text(reflectionTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)

                    Group {
                        switch reflectionStep {
                        case 0: rpeStep
                        case 1: highlightStep
                        case 2: nextFocusStep
                        case 3: moodStep
                        default: EmptyView()
                        }
                    }
                    .id(reflectionStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    // Navigation
                    HStack(spacing: Spacing.lg) {
                        if reflectionStep > 0 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    reflectionStep -= 1
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("BACK")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.dsOnSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dsSurfaceContainerHigh)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                                .ghostBorder()
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            if reflectionStep < 3 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    reflectionStep += 1
                                }
                            } else {
                                Task { await viewModel.saveSession() }
                            }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(Color.dsCTALabel)
                                } else {
                                    Text(reflectionStep < 3 ? "NEXT" : "SAVE SESSION")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .tracking(2)
                                }
                            }
                            .foregroundStyle(Color.dsCTALabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DSGradient.primaryCTA)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                        }
                        .disabled(viewModel.isLoading)
                    }

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.dsError)
                    }
                }
                .padding(Spacing.xl)
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            guard Date() > ignoreTranscriptsUntil else { return }
            processReflectionVoiceCommand(newTranscript)
        }
    }

    // MARK: - Voice Commands

    private func processReflectionVoiceCommand(_ transcript: String) {
        var commands: [VoiceCommand] = [
            VoiceCommand(label: "Next", phrases: ["next", "continue"]) {
                if reflectionStep < 3 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        reflectionStep += 1
                    }
                }
            },
            VoiceCommand(label: "Back", phrases: ["back", "previous"]) {
                if reflectionStep > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        reflectionStep -= 1
                    }
                }
            },
            VoiceCommand(label: "Save", phrases: ["save", "done", "finish"]) {
                if reflectionStep == 3 {
                    Task { await viewModel.saveSession() }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        reflectionStep = 3
                    }
                }
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]

        // Step-specific mood commands
        if reflectionStep == 3 {
            for mood in moodOptions {
                commands.append(VoiceCommand(label: mood.label, phrases: [mood.label.lowercased(), mood.name.lowercased()]) {
                    viewModel.reflectionMood = mood.name.lowercased()
                })
            }
        }

        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
            return
        }

        // Number extraction for RPE (step 0 only)
        if reflectionStep == 0 {
            if let number = VoiceCommandMatcher.extractNumber(from: transcript), number >= 1, number <= 10 {
                viewModel.reflectionRPE = number
                lastVoiceCommand = "RPE: \(number)"
            }
        }
    }

    // MARK: - Steps

    private var rpeStep: some View {
        VStack(spacing: 16) {
            Text(rpeEmoji)
                .font(.system(size: 48))
            Text("\(viewModel.reflectionRPE)")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
            Text("/ 10")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Slider(
                value: Binding(
                    get: { Double(viewModel.reflectionRPE) },
                    set: { viewModel.reflectionRPE = Int($0) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(Color.dsAccentOrange)
            HStack {
                Text("EASY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Spacer()
                Text("MAXIMUM")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private var highlightStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What went well? (up to 3)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            if viewModel.highlightOptions.isEmpty {
                HStack {
                    Spacer()
                    ProgressView().tint(Color.dsSecondary)
                    Spacer()
                }
                .padding()
            } else {
                ChipPickerView(
                    items: viewModel.highlightOptions.map { ChipItem(id: $0.id, label: $0.label) },
                    selectedIds: $viewModel.selectedHighlights,
                    maxSelection: 3,
                    accentColor: .dsSecondary
                )
            }
        }
    }

    private var nextFocusStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What to work on next? (up to 2)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            if viewModel.nextFocusOptions.isEmpty {
                HStack {
                    Spacer()
                    ProgressView().tint(Color.dsSecondary)
                    Spacer()
                }
                .padding()
            } else {
                ChipPickerView(
                    items: viewModel.nextFocusOptions.map { ChipItem(id: $0.id, label: $0.label) },
                    selectedIds: $viewModel.selectedNextFocus,
                    maxSelection: 2,
                    accentColor: .dsSecondary
                )
            }
        }
    }

    private var moodStep: some View {
        VStack(spacing: 16) {
            Text("How do you feel after training?")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            HStack(spacing: 10) {
                ForEach(moodOptions, id: \.name) { mood in
                    let isSelected = viewModel.reflectionMood == mood.name.lowercased()
                    Button {
                        viewModel.reflectionMood = mood.name.lowercased()
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 28))
                            Text(mood.label.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(isSelected ? Color.dsSecondary : Color.dsOnSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.dsSecondary.opacity(0.4) : .clear, lineWidth: 1.5)
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
        case 1...3: return "\u{1F60C}"
        case 4...6: return "\u{1F624}"
        case 7...8: return "\u{1F4AA}"
        case 9...10: return "\u{1F525}"
        default: return "\u{1F624}"
        }
    }
}
