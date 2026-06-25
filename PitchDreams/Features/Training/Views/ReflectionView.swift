import SwiftUI

struct ReflectionView: View {
    @ObservedObject var viewModel: ActiveTrainingViewModel
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @State private var showNote = false
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
                    Text("How did that go?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)

                    effortCard
                    moodCard
                    optionalNote

                    saveButton

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

    // MARK: - Effort

    private var effortCard: some View {
        sectionCard(title: "HOW HARD WAS THAT?") {
            VStack(spacing: 16) {
                Text(rpeEmoji)
                    .font(.system(size: 44))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.reflectionRPE)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("/ 10")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
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
        }
    }

    // MARK: - Mood

    private var moodCard: some View {
        sectionCard(title: "HOW DO YOU FEEL?") {
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

    // MARK: - Optional Note (not a gate)

    private var optionalNote: some View {
        VStack(spacing: Spacing.lg) {
            Button {
                withAnimation(.dsSnappy) { showNote.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showNote ? "chevron.down" : "plus.circle")
                        .font(.system(size: 14, weight: .bold))
                    Text(showNote ? "HIDE NOTE" : "ADD A NOTE (OPTIONAL)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                    Spacer()
                }
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if showNote {
                sectionCard(title: "WHAT WENT WELL? (UP TO 3)") {
                    if viewModel.highlightOptions.isEmpty {
                        centeredSpinner
                    } else {
                        ChipPickerView(
                            items: viewModel.highlightOptions.map { ChipItem(id: $0.id, label: $0.label) },
                            selectedIds: $viewModel.selectedHighlights,
                            maxSelection: 3,
                            accentColor: .dsSecondary
                        )
                    }
                }

                sectionCard(title: "WHAT TO WORK ON NEXT? (UP TO 2)") {
                    if viewModel.nextFocusOptions.isEmpty {
                        centeredSpinner
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
        }
    }

    private var saveButton: some View {
        Button {
            Task { await viewModel.saveSession() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.dsCTALabel)
                } else {
                    Text("SAVE SESSION")
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
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private var centeredSpinner: some View {
        HStack {
            Spacer()
            ProgressView().tint(Color.dsSecondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - Voice Commands

    private func processReflectionVoiceCommand(_ transcript: String) {
        var commands: [VoiceCommand] = [
            VoiceCommand(label: "Save", phrases: ["save", "done", "finish"]) {
                Task { await viewModel.saveSession() }
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]

        for mood in moodOptions {
            commands.append(VoiceCommand(label: mood.label, phrases: [mood.label.lowercased(), mood.name.lowercased()]) {
                viewModel.reflectionMood = mood.name.lowercased()
            })
        }

        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
            return
        }

        // Number extraction for effort (RPE)
        if let number = VoiceCommandMatcher.extractNumber(from: transcript), number >= 1, number <= 10 {
            viewModel.reflectionRPE = number
            lastVoiceCommand = "RPE: \(number)"
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
        .ghostBorder()
    }

    // MARK: - Helpers

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
