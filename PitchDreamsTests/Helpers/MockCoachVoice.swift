import Foundation
@testable import PitchDreams

@MainActor
final class MockCoachVoice: CoachVoiceProtocol {
    var isSpeaking: Bool = false
    var lastSpokeAt: Date?
    var onWillSpeak: (() -> Void)?
    var onDidFinishSpeaking: (() -> Void)?
    private(set) var spokenTexts: [String] = []
    private(set) var speakCallCount: Int = 0
    private(set) var stopCallCount: Int = 0
    private(set) var lastPersonality: String?
    private(set) var lastRate: Double = 1.0

    /// When true, calling speak() sets isSpeaking to true and it stays true until stop() is called.
    /// When false (default), speak() is instant (isSpeaking stays false).
    var simulateSpeaking: Bool = false

    func speak(_ text: String, personality: String, rate: Double) {
        onWillSpeak?()
        speakCallCount += 1
        spokenTexts.append(text)
        lastPersonality = personality
        lastRate = rate
        if simulateSpeaking {
            isSpeaking = true
        }
    }

    func stop() {
        stopCallCount += 1
        isSpeaking = false
    }

    func isSpeakingOrCoolingDown(cooldown: TimeInterval = 2.0) -> Bool {
        if isSpeaking { return true }
        guard let lastSpokeAt else { return false }
        return Date().timeIntervalSince(lastSpokeAt) < cooldown
    }

    /// Simulate speech finishing (for auto-advance tests).
    func finishSpeaking() {
        isSpeaking = false
        lastSpokeAt = Date()
        onDidFinishSpeaking?()
    }
}
