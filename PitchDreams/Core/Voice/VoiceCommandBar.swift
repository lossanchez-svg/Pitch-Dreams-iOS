import SwiftUI

struct VoiceCommandBar: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @Binding var lastCommand: String?

    @State private var showCommand = false
    @State private var showPermissionAlert = false

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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
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

#Preview {
    VStack {
        Spacer()
        VoiceCommandBar(
            speechRecognizer: SpeechRecognizer(),
            lastCommand: .constant("Start Training")
        )
    }
}
