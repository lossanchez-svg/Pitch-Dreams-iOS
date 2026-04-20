import SwiftUI

struct SpaceSelectionView: View {
    let childId: String
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var lastVoiceCommand: String?
    @State private var selectedSpaceId: String?
    @State private var paywallSpaceId: String?
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

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
                        let hasPremium = entitlementStore.has(.advancedDrills)
                        let drills = DrillRegistry.drills(for: space.id, hasPremium: hasPremium)
                        let premiumCount = DrillRegistry.premiumDrills(for: space.id).count

                        VStack(spacing: 8) {
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

                            if !hasPremium && premiumCount > 0 {
                                advancedDrillsFooter(count: premiumCount, spaceId: space.id)
                            }
                        }
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
        .navigationDestination(isPresented: Binding(
            get: { selectedSpaceId != nil },
            set: { if !$0 { selectedSpaceId = nil } }
        )) {
            if let spaceId = selectedSpaceId {
                ActiveDrillView(
                    childId: childId,
                    drills: DrillRegistry.drills(
                        for: spaceId,
                        hasPremium: entitlementStore.has(.advancedDrills)
                    ),
                    spaceType: spaceId
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { paywallSpaceId != nil },
            set: { if !$0 { paywallSpaceId = nil } }
        )) {
            PaywallView(
                manager: subscriptionManager,
                entitlementStore: entitlementStore,
                context: .advancedDrills
            )
        }
    }

    private func processVoiceCommand(_ transcript: String) {
        let commands: [VoiceCommand] = [
            VoiceCommand(label: "Small Indoor", phrases: ["small", "bedroom", "hallway"]) {
                selectSpace("small_indoor")
            },
            VoiceCommand(label: "Large Indoor", phrases: ["large", "gym", "garage"]) {
                selectSpace("large_indoor")
            },
            VoiceCommand(label: "Outdoor", phrases: ["outdoor", "field", "park", "outside"]) {
                selectSpace("outdoor")
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]

        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
        }
    }

    private func selectSpace(_ spaceId: String) {
        let drills = DrillRegistry.drills(for: spaceId)
        guard !drills.isEmpty else { return }
        selectedSpaceId = spaceId
    }

    // MARK: - Advanced drills footer (Model 1 parent-unlock framing)

    private func advancedDrillsFooter(count: Int, spaceId: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            paywallSpaceId = spaceId
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color.dsAccentOrange)
                Text("\(count) advanced \(count == 1 ? "drill" : "drills") • Ask your family to unlock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.dsSurfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.dsAccentOrange.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) advanced drills locked. Tap to open the family unlock screen.")
    }
}
