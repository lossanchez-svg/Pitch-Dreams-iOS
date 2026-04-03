import SwiftUI

/// Manages tap-to-inspect on pitch elements with popover, coach voice, and haptics.
@MainActor
final class InteractivePitchViewModel: ObservableObject {
    @Published var selectedElementId: String?
    @Published var popoverText: String = ""
    @Published var popoverPosition: CGPoint = .zero

    private let voice: CoachVoiceProtocol?

    init(voice: CoachVoiceProtocol? = nil) {
        self.voice = voice
    }

    /// Handle a tap on a pitch element. Builds a description and shows the popover.
    func tapPlayer(_ player: TacticalPlayer, at position: CGPoint) {
        selectedElementId = player.id
        popoverPosition = position
        popoverText = descriptionForPlayer(player)
        voice?.speak(popoverText, personality: "manager")
    }

    func tapArrow(_ arrow: TacticalArrow, at position: CGPoint) {
        selectedElementId = arrow.id
        popoverPosition = position
        popoverText = descriptionForArrow(arrow)
        voice?.speak(popoverText, personality: "manager")
    }

    func tapZone(_ zone: TacticalZone, at position: CGPoint) {
        selectedElementId = zone.id
        popoverPosition = position
        popoverText = descriptionForZone(zone)
        voice?.speak(popoverText, personality: "manager")
    }

    /// Dismiss the popover.
    func dismiss() {
        selectedElementId = nil
        popoverText = ""
    }

    // MARK: - Description Builders

    func descriptionForPlayer(_ player: TacticalPlayer) -> String {
        if let desc = player.description, !desc.isEmpty {
            return desc
        }
        let role: String
        switch player.type {
        case .self_:
            role = "You"
        case .teammate:
            role = "Teammate"
        case .opponent:
            role = "Opponent"
        }
        if let label = player.label, !label.isEmpty {
            return "\(role): \(label)"
        }
        return role
    }

    func descriptionForArrow(_ arrow: TacticalArrow) -> String {
        if let desc = arrow.description, !desc.isEmpty {
            return desc
        }
        let action: String
        switch arrow.type {
        case .pass: action = "Pass"
        case .run: action = "Run"
        case .scan: action = "Scan"
        case .space: action = "Space"
        }
        if let label = arrow.label, !label.isEmpty {
            return "\(action): \(label)"
        }
        return action
    }

    func descriptionForZone(_ zone: TacticalZone) -> String {
        if let desc = zone.description, !desc.isEmpty {
            return desc
        }
        let zoneType: String
        switch zone.type {
        case .space: zoneType = "Open space"
        case .danger: zoneType = "Danger zone"
        case .opportunity: zoneType = "Opportunity"
        }
        if let label = zone.label, !label.isEmpty {
            return "\(zoneType): \(label)"
        }
        return zoneType
    }
}
