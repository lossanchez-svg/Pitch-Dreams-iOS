import Foundation

struct VoiceCommand {
    let label: String
    let phrases: [String]
    let action: () -> Void
}

struct VoiceCommandMatcher {
    /// Match transcript against commands using word-boundary matching.
    /// Prevents false positives like "done" matching a "one" command.
    static func match(transcript: String, commands: [VoiceCommand]) -> VoiceCommand? {
        let lower = transcript.lowercased()
        for command in commands {
            for phrase in command.phrases {
                if containsWholePhrase(lower, phrase: phrase.lowercased()) {
                    return command
                }
            }
        }
        return nil
    }

    /// Checks if `text` contains `phrase` as whole words (word-boundary match).
    /// "I am done" contains "done" ✓, but "d-one" does not contain "one" ✓
    private static func containsWholePhrase(_ text: String, phrase: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: phrase))\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    /// Extract spoken numbers: "five" -> 5, "twenty three" -> 23, "42" -> 42
    static func extractNumber(from transcript: String) -> Int? {
        let lower = transcript.lowercased()
        let wordToNumber: [String: Int] = [
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
            "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
            "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
            "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
            "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
            "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
            "eighty": 80, "ninety": 90, "hundred": 100,
        ]

        // Try word-based first (word-boundary match)
        for (word, number) in wordToNumber {
            if containsWholePhrase(lower, phrase: word) {
                return number
            }
        }

        // Try digit extraction
        let digits = lower.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let num = Int(digits), num > 0 {
            return num
        }

        return nil
    }
}
