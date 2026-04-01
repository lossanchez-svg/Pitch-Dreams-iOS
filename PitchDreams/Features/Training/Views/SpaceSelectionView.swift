import SwiftUI

struct SpaceSelectionView: View {
    let childId: String
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var lastVoiceCommand: String?
    @State private var navigateToSpace: String?

    private let spaces: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("small_indoor", "Small Indoor", "Bedroom, hallway, or small room", "house.fill"),
        ("large_indoor", "Large Indoor", "Gym, garage, or large room", "building.2.fill"),
        ("outdoor", "Outdoor", "Field, park, or driveway", "sun.max.fill"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Where are you training?")
                    .font(.title2.bold())
                    .padding(.top, 8)

                Text("We'll pick the best drills for your space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(spaces, id: \.id) { space in
                    let drills = DrillRegistry.drills(for: space.id)
                    NavigationLink {
                        ActiveDrillView(
                            childId: childId,
                            drills: drills,
                            spaceType: space.id
                        )
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: space.icon)
                                .font(.title)
                                .foregroundStyle(.orange)
                                .frame(width: 48, height: 48)
                                .background(.orange.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(space.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(space.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(drills.count) drills available")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(drills.isEmpty)
                    .opacity(drills.isEmpty ? 0.5 : 1)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            if speechRecognizer.isListening {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationTitle("Pick a Space")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isListening ? .red : .cyan)
                }
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            processVoiceCommand(newTranscript)
        }
    }

    private func processVoiceCommand(_ transcript: String) {
        let lower = transcript.lowercased()

        // Space selection by voice
        if lower.contains("small") || lower.contains("bedroom") || lower.contains("hallway") {
            lastVoiceCommand = "Small Indoor"
            navigateToSpace = "small_indoor"
        } else if lower.contains("large") || lower.contains("gym") || lower.contains("garage") {
            lastVoiceCommand = "Large Indoor"
            navigateToSpace = "large_indoor"
        } else if lower.contains("outdoor") || lower.contains("field") || lower.contains("park") || lower.contains("outside") {
            lastVoiceCommand = "Outdoor"
            navigateToSpace = "outdoor"
        } else if lower.contains("mic off") || lower.contains("stop listening") {
            speechRecognizer.stopListening()
            lastVoiceCommand = "Mic Off"
        }
    }
}
