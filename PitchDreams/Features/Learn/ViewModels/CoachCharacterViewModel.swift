import Foundation
import Combine

// MARK: - Coach Mood

enum CoachMood: String {
    case idle
    case speaking
    case encouraging
    case celebrating
    case listening
    case skeptical
}

// MARK: - Coach Size

enum CoachSize {
    case sm, md, lg

    var points: CGFloat {
        switch self {
        case .sm: return 64
        case .md: return 96
        case .lg: return 128
        }
    }
}

// MARK: - ViewModel

@MainActor
final class CoachCharacterViewModel: ObservableObject {
    @Published private(set) var mood: CoachMood = .idle
    @Published private(set) var speechText: String = ""
    @Published private(set) var isSpeaking: Bool = false

    private var transientTask: Task<Void, Never>?

    /// Show a speech bubble and set speaking mood.
    func speak(_ text: String) {
        transientTask?.cancel()
        speechText = text
        isSpeaking = true
        mood = .speaking
    }

    /// Clear speech bubble and return to idle.
    func stopSpeaking() {
        transientTask?.cancel()
        speechText = ""
        isSpeaking = false
        mood = .idle
    }

    /// Set listening mood (e.g. during voice input).
    func listen() {
        transientTask?.cancel()
        mood = .listening
        isSpeaking = false
    }

    /// Set a transient mood that auto-returns to idle after `duration` seconds.
    func setMood(_ newMood: CoachMood, duration: TimeInterval = 3.0) {
        transientTask?.cancel()
        mood = newMood

        // Transient moods auto-return to idle
        if newMood == .encouraging || newMood == .celebrating || newMood == .skeptical {
            transientTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else { return }
                self?.mood = .idle
            }
        }
    }
}
