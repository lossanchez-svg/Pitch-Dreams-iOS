import AVFoundation

@MainActor
final class CoachVoice: ObservableObject, CoachVoiceProtocol {
    @Published var isSpeaking = false
    private(set) var lastSpokeAt: Date?
    var onWillSpeak: (() -> Void)?
    var onDidFinishSpeaking: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: CoachVoiceDelegate?
    private var resolvedVoice: AVSpeechSynthesisVoice?

    init() {
        delegate = CoachVoiceDelegate { [weak self] in
            Task { @MainActor in
                self?.isSpeaking = false
                self?.lastSpokeAt = Date()
                self?.onDidFinishSpeaking?()
            }
        }
        synthesizer.delegate = delegate
        resolvedVoice = Self.bestAvailableVoice()
    }

    func isSpeakingOrCoolingDown(cooldown: TimeInterval = 2.0) -> Bool {
        if isSpeaking { return true }
        guard let lastSpokeAt else { return false }
        return Date().timeIntervalSince(lastSpokeAt) < cooldown
    }

    func speak(_ text: String, personality: String = "manager", rate: Double = 1.0) {
        onWillSpeak?()
        stop()

        // Ensure audio session is active for speech output.
        // Uses the same category/options as SpeechRecognizer so it's a no-op
        // if the recognizer already configured it — avoids disrupting Bluetooth routes.
        try? AVAudioSession.sharedInstance().setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .duckOthers, .allowBluetooth, .allowBluetoothA2DP]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = resolvedVoice ?? AVSpeechSynthesisVoice(language: "en-US")

        // Natural pacing: slight pauses between sentences
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.05

        let baseRate: Float
        switch personality {
        case "hype":
            baseRate = 0.50
            utterance.pitchMultiplier = 1.08
            utterance.volume = 1.0
        case "zen":
            baseRate = 0.42
            utterance.pitchMultiplier = 0.95
            utterance.volume = 0.9
        case "drill":
            baseRate = 0.50
            utterance.pitchMultiplier = 0.85
            utterance.volume = 1.0
        default: // manager — warm, encouraging coach tone
            baseRate = 0.46
            utterance.pitchMultiplier = 1.02
            utterance.volume = 0.95
        }
        // Apply the F4 slow-mo multiplier. Clamped to AVSpeech's legal range
        // so 0.25× doesn't underflow to silence.
        let scaledRate = baseRate * Float(max(0.25, min(2.0, rate)))
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, scaledRate))

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - Voice Selection

    /// Pick the best available en-US voice, preferring premium > enhanced > default.
    /// Premium voices (Siri-quality) are downloaded on-device and sound very natural.
    private static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let enUS = allVoices.filter { $0.language == "en-US" }

        // Preferred voice identifiers (warm, clear, good for coaching kids)
        let preferred = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.premium.en-US.Ava",
            "com.apple.voice.premium.en-US.Evan",
            "com.apple.voice.premium.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.voice.enhanced.en-US.Evan",
            "com.apple.voice.enhanced.en-US.Samantha",
        ]

        // Try preferred voices first
        for id in preferred {
            if let voice = enUS.first(where: { $0.identifier == id }) {
                return voice
            }
        }

        // Fall back to any premium voice
        if let premium = enUS.first(where: { $0.quality == .premium }) {
            return premium
        }

        // Fall back to any enhanced voice
        if let enhanced = enUS.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }

        // Last resort: default system voice
        return AVSpeechSynthesisVoice(language: "en-US")
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
