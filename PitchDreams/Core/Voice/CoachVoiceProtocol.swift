import Foundation

/// Protocol abstracting CoachVoice for testability.
/// Real implementation uses AVSpeechSynthesizer; mock records calls synchronously.
@MainActor
protocol CoachVoiceProtocol: AnyObject {
    var isSpeaking: Bool { get }
    /// Timestamp of when the coach last finished speaking.
    var lastSpokeAt: Date? { get }
    /// Speak with an optional playback-rate multiplier. `rate = 1.0` is
    /// normal; `rate = 0.5` is half-speed (F4 slow-mo). Defaults to normal
    /// via the protocol extension below so existing call sites don't change.
    func speak(_ text: String, personality: String, rate: Double)
    func stop()

    /// Returns true if the coach is speaking or recently finished (within cooldown).
    func isSpeakingOrCoolingDown(cooldown: TimeInterval) -> Bool

    /// Called just before speech synthesis begins. Use to pause the speech recognizer.
    var onWillSpeak: (() -> Void)? { get set }
    /// Called after speech synthesis finishes. Use to resume the speech recognizer.
    var onDidFinishSpeaking: (() -> Void)? { get set }
}

extension CoachVoiceProtocol {
    /// Convenience overload used by existing call sites.
    func speak(_ text: String, personality: String) {
        speak(text, personality: personality, rate: 1.0)
    }
}
