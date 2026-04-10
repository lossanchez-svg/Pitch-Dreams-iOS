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
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    VStack(spacing: 8) {
                        Text("SELECT SPACE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Color.dsSecondary)

                        Text("Where are you\ntraining?")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.dsOnSurface)

                        Text("We'll pick the best drills for your space.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    .padding(.top, 16)

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
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.dsAccentOrange.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: space.icon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.dsAccentOrange)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(space.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.dsOnSurface)
                                    Text(space.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.dsOnSurfaceVariant)
                                    Text("\(drills.count) drills available")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.dsSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.dsOnSurfaceVariant)
                            }
                            .padding(Spacing.lg)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .ghostBorder()
                        }
                        .buttonStyle(.plain)
                        .disabled(drills.isEmpty)
                        .opacity(drills.isEmpty ? 0.4 : 1)
                    }
                }
                .padding(Spacing.xl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if speechRecognizer.isListening {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isListening ? .red : Color.dsSecondary)
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
