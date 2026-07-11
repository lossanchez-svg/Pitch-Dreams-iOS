import SwiftUI

struct VoiceCommandBar: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @Binding var lastCommand: String?

    @State private var showCommand = false
    @State private var showPermissionAlert = false
    @State private var showVoiceHint = false
    @AppStorage("voiceCommandHintShown") private var voiceHintShown = false

    var body: some View {
        HStack(spacing: 12) {
            // Mic button
            Button {
                Task {
                    await speechRecognizer.toggleListening()
                    if speechRecognizer.permissionDenied {
                        showPermissionAlert = true
                    }
                }
            } label: {
                Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                    .font(.title3)
                    .foregroundStyle(speechRecognizer.isListening ? .red : .primary)
                    .frame(width: 44, height: 44)
                    .background(speechRecognizer.isListening ? Color.red.opacity(0.15) : Color.dsSurfaceContainerHighest)
                    .clipShape(Circle())
                    .scaleEffect(speechRecognizer.isListening ? 1.1 : 1.0)
                    .animation(
                        speechRecognizer.isListening
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: speechRecognizer.isListening
                    )
            }
            .buttonStyle(.plain)

            // Transcript or last command
            if showCommand, let command = lastCommand {
                Text(command)
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                    .transition(.opacity)
            } else if !speechRecognizer.transcript.isEmpty {
                Text(speechRecognizer.transcript)
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else if speechRecognizer.isListening {
                Text("Listening...")
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
            } else if let errorText = speechRecognizer.error {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            // What can I say?
            Button {
                showVoiceHint = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voice command help")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .onAppear {
            // First time the mic bar ever appears, teach the commands once.
            if !voiceHintShown {
                voiceHintShown = true
                showVoiceHint = true
            }
        }
        .sheet(isPresented: $showVoiceHint) {
            VoiceHintSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Voice needs permission", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("To use voice commands, allow Microphone and Speech Recognition for PitchDreams in Settings.")
        }
        .onChange(of: lastCommand) { newValue in
            guard newValue != nil else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                showCommand = true
            }
            // Fade out after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeOut(duration: 0.5)) {
                    showCommand = false
                }
            }
        }
    }
}

// MARK: - Voice Hint Sheet

struct VoiceHintSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let commands: [(phrase: String, does: String)] = [
        ("\u{201C}Start\u{201D}", "Start the drill or timer"),
        ("\u{201C}Pause\u{201D} / \u{201C}Resume\u{201D}", "Pause or continue"),
        ("\u{201C}Done\u{201D} / \u{201C}Next\u{201D}", "Finish and move on"),
        ("A number, like \u{201C}seven\u{201D}", "Set reps or effort"),
        ("\u{201C}Mic off\u{201D}", "Stop listening"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundStyle(Color.dsSecondary)
                Text("Talk to your coach")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
            }

            Text("Hands on the ball? Just say it out loud:")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(commands, id: \.phrase) { command in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(command.phrase)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsSecondary)
                            .frame(width: 150, alignment: .leading)
                        Text(command.does)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))

            Text("Voice is optional — tapping always works too.")
                .font(.system(size: 12))
                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.8))

            Button {
                dismiss()
            } label: {
                Text("GOT IT")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DSGradient.primaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.dsBackground)
    }
}

#Preview {
    VStack {
        Spacer()
        VoiceCommandBar(
            speechRecognizer: SpeechRecognizer(),
            lastCommand: .constant("Start Training")
        )
    }
}

#Preview("Hint Sheet") {
    VoiceHintSheet()
}
