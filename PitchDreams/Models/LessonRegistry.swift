import Foundation

enum LessonRegistry {
    static let titles: [String: String] = [
        "3point-scan": "3-Point Scan",
        "receive-decide-execute": "Receive-Decide-Execute",
        "patience-in-possession": "Patience in Possession",
        "check-your-shoulder": "Check Your Shoulder",
        "press-triggers": "Press Triggers",
        "third-man-run": "Third Man Run",
        "switching-the-play": "Switching the Play",
        "blind-side-movement": "Blind Side Movement",
        "controlling-the-tempo": "Controlling the Tempo",
        "breathing-under-pressure": "Breathing Under Pressure",
    ]

    static func title(for id: String) -> String {
        titles[id] ?? id.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
