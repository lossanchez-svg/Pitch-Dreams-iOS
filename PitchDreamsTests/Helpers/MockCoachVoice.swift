import Foundation
@testable import PitchDreams

@MainActor
final class MockCoachVoice: CoachVoiceProtocol {
    private(set) var isSpeaking: Bool = false
    private(set) var spokenTexts: [String] = []
    private(set) var speakCallCount: Int = 0
    private(set) var stopCallCount: Int = 0
    private(set) var lastPersonality: String?

    /// When true, calling speak() sets isSpeaking to true and it stays true until stop() is called.
    /// When false (default), speak() is instant (isSpeaking stays false).
    var simulateSpeaking: Bool = false

    func speak(_ text: String, personality: String) {
        speakCallCount += 1
        spokenTexts.append(text)
        lastPersonality = personality
        if simulateSpeaking {
            isSpeaking = true
        }
    }

    func stop() {
        stopCallCount += 1
        isSpeaking = false
    }

    /// Simulate speech finishing (for auto-advance tests).
    func finishSpeaking() {
        isSpeaking = false
    }
}
