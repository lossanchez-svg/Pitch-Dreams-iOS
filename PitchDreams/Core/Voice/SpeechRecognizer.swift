import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var error: String?

    /// Tracks whether user wants continuous listening (vs internal restart cycles)
    private var wantsListening = false
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestPermission() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            error = "Speech recognition not authorized"
            return false
        }

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

        cleanup()
        wantsListening = true

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request else { return }
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
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

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, recognitionError in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }

                    if let recognitionError {
                        let nsError = recognitionError as NSError
                        // Silence timeout (1110) or end-of-speech (1101) — debounce restart
                        if nsError.domain == "kAFAssistantErrorDomain" &&
                           (nsError.code == 1110 || nsError.code == 1101) {
                            self.cleanup()
                            if self.wantsListening {
                                try? await Task.sleep(nanoseconds: 600_000_000)
                                if self.wantsListening {
                                    self.startListening()
                                }
                            }
                            return
                        }
                        self.error = recognitionError.localizedDescription
                        self.stopListening()
                        return
                    }

                    if result?.isFinal == true {
                        self.cleanup()
                        if self.wantsListening {
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            if self.wantsListening {
                                self.startListening()
                            }
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
        wantsListening = false
        cleanup()
        isListening = false
    }

    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        request?.endAudio()
        request = nil
        isListening = false
    }

    func toggleListening() async {
        if wantsListening {
            stopListening()
        } else {
            let granted = await requestPermission()
            if granted {
                startListening()
            }
        }
    }
}
