import AVFoundation

@MainActor
final class CoachVoice: ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: CoachVoiceDelegate?

    init() {
        delegate = CoachVoiceDelegate { [weak self] in
            Task { @MainActor in
                self?.isSpeaking = false
            }
        }
        synthesizer.delegate = delegate
    }

    func speak(_ text: String, personality: String = "manager") {
        stop()

        // Configure audio session for speech output (SpeechRecognizer sets .record which blocks TTS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        switch personality {
        case "hype":
            utterance.rate = 0.52
            utterance.pitchMultiplier = 1.1
        case "zen":
            utterance.rate = 0.42
            utterance.pitchMultiplier = 0.9
        case "drill":
            utterance.rate = 0.52
            utterance.pitchMultiplier = 0.8
        default: // manager
            utterance.rate = 0.48
            utterance.pitchMultiplier = 1.0
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

// MARK: - Delegate

private final class CoachVoiceDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish()
    }
}
