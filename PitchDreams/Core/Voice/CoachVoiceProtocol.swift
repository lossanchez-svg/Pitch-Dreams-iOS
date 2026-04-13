import Foundation

/// Protocol abstracting CoachVoice for testability.
/// Real implementation uses AVSpeechSynthesizer; mock records calls synchronously.
@MainActor
protocol CoachVoiceProtocol: AnyObject {
    var isSpeaking: Bool { get }
    /// Timestamp of when the coach last finished speaking.
    var lastSpokeAt: Date? { get }
    func speak(_ text: String, personality: String)
    func stop()

    /// Returns true if the coach is speaking or recently finished (within cooldown).
    func isSpeakingOrCoolingDown(cooldown: TimeInterval) -> Bool

    /// Called just before speech synthesis begins. Use to pause the speech recognizer.
    var onWillSpeak: (() -> Void)? { get set }
    /// Called after speech synthesis finishes. Use to resume the speech recognizer.
    var onDidFinishSpeaking: (() -> Void)? { get set }
}
