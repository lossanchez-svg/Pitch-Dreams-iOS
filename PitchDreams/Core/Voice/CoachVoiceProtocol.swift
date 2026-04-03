import Foundation

/// Protocol abstracting CoachVoice for testability.
/// Real implementation uses AVSpeechSynthesizer; mock records calls synchronously.
@MainActor
protocol CoachVoiceProtocol: AnyObject {
    var isSpeaking: Bool { get }
    func speak(_ text: String, personality: String)
    func stop()
}
