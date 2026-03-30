import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var error: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestPermission() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            error = "Speech recognition not authorized"
            return false
        }

        // Request microphone permission
        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        guard micGranted else {
            error = "Microphone access not granted"
            return false
        }
        return true
    }

    func startListening() {
        guard let recognizer, recognizer.isAvailable else {
            error = "Speech recognition unavailable"
            return
        }

        // Clean up any previous session before starting
        stopListeningInternal()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request else { return }
            request.shouldReportPartialResults = true
            if #available(iOS 16, *) {
                // Try on-device first for privacy, but fall back to server if unavailable
                if recognizer.supportsOnDeviceRecognition {
                    request.requiresOnDeviceRecognition = true
                }
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            transcript = ""

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if let error {
                        // Silence timeout is normal -- not a real error
                        let nsError = error as NSError
                        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                            // Timeout -- restart if still listening
                            if self.isListening {
                                self.stopListening()
                                self.startListening()
                            }
                            return
                        }
                        self.error = error.localizedDescription
                        self.stopListening()
                    }
                    if result?.isFinal == true {
                        // Recognition complete -- restart for continuous listening
                        if self.isListening {
                            self.stopListening()
                            self.startListening()
                        }
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
            stopListening()
        }
    }

    func stopListening() {
        stopListeningInternal()
        isListening = false
    }

    /// Internal cleanup without setting isListening to false (used by startListening to reset state)
    private func stopListeningInternal() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        // Only remove tap if one was installed (engine has been prepared/started)
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        request?.endAudio()
        request = nil
    }

    func restartListening() {
        stopListening()
        startListening()
    }

    func toggleListening() async {
        if isListening {
            stopListening()
        } else {
            let granted = await requestPermission()
            if granted {
                startListening()
            }
        }
    }
}
