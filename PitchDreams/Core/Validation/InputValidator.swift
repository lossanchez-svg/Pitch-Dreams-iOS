import Foundation

/// Central input-validation helpers used across onboarding and settings.
/// Each validator returns `nil` when input is acceptable, or a short
/// user-facing error string when it isn't — suitable for inline display
/// beneath the input field.
enum InputValidator {

    // MARK: - Email

    /// Simple but practical email check. Deliberately not RFC-5322
    /// exhaustive — false positives annoy users more than false negatives.
    static func email(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }  // don't nag while empty
        let pattern = #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#
        let ok = trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        return ok ? nil : "Enter a valid email address."
    }

    // MARK: - Password

    /// Minimum strength. Surfaces the first missing requirement so the user
    /// knows what to fix.
    static func password(_ raw: String) -> String? {
        if raw.isEmpty { return nil }
        if raw.count < 8 { return "At least 8 characters." }
        if !raw.contains(where: { $0.isLetter }) { return "Include at least one letter." }
        if !raw.contains(where: { $0.isNumber }) { return "Include at least one number." }
        return nil
    }

    /// 0–3 strength score for a live strength meter.
    static func passwordStrength(_ raw: String) -> Int {
        var score = 0
        if raw.count >= 8 { score += 1 }
        if raw.count >= 12 { score += 1 }
        if raw.contains(where: { $0.isLetter }) && raw.contains(where: { $0.isNumber }) { score += 1 }
        return min(3, score)
    }

    static func passwordsMatch(_ password: String, _ confirm: String) -> String? {
        if confirm.isEmpty { return nil }
        return password == confirm ? nil : "Passwords don't match."
    }

    // MARK: - PIN

    /// PINs must be 4 digits. Guessable sequences are rejected so siblings
    /// can't obvious-guess each other's logins.
    static func pin(_ raw: String) -> String? {
        if raw.isEmpty { return nil }
        if !raw.allSatisfy(\.isNumber) { return "Numbers only." }
        if raw.count < 4 { return "PIN must be 4 digits." }
        if raw.count > 6 { return "PIN can't be more than 6 digits." }
        if Self.bannedPins.contains(raw) { return "Pick something less obvious." }
        if Self.isAllSameDigit(raw) { return "Not every digit the same, please." }
        if Self.isAscendingSequence(raw) || Self.isDescendingSequence(raw) {
            return "Sequential digits are too easy to guess."
        }
        return nil
    }

    static func pinsMatch(_ pin: String, _ confirm: String) -> String? {
        if confirm.isEmpty { return nil }
        return pin == confirm ? nil : "PINs don't match."
    }

    // MARK: - Nickname

    /// Two to twenty characters, alphanumerics + hyphen/underscore + spaces,
    /// no profanity-blocklist hits. Kids pick silly names — we allow
    /// whimsy, block hate and slurs.
    static func nickname(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        if trimmed.count < 2 { return "At least 2 characters." }
        if trimmed.count > 20 { return "Max 20 characters." }

        let allowed = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: " -_"))
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return "Letters, numbers, spaces, -, and _ only."
        }
        let lower = trimmed.lowercased()
        if Self.profanityBlocklist.contains(where: { lower.contains($0) }) {
            return "Pick a different nickname."
        }
        return nil
    }

    // MARK: - Private helpers

    /// Most-guessed PINs per publicly-reported analyses of breached datasets.
    /// Kept as a short high-value blocklist, not an exhaustive list.
    private static let bannedPins: Set<String> = [
        "0000", "1111", "2222", "3333", "4444", "5555",
        "6666", "7777", "8888", "9999",
        "1234", "4321", "1212", "2121", "1122", "2211",
        "0123", "1234", "2345", "3456", "4567", "5678", "6789",
        "111111", "123456", "654321", "000000", "121212"
    ]

    /// Small blocklist aimed at obvious hate speech + crude slurs. Intentionally
    /// narrow — nicknames for youth soccer are mostly silly, and over-blocking
    /// frustrates legitimate picks. Expand in response to real reports.
    private static let profanityBlocklist: [String] = [
        "fuck", "shit", "bitch", "nigg", "faggot", "fag", "slut", "whore",
        "cunt", "dick", "asshole", "bastard", "retard", "kike", "chink",
        "spic", "wetback", "coon"
    ]

    private static func isAllSameDigit(_ raw: String) -> Bool {
        guard let first = raw.first else { return false }
        return raw.allSatisfy { $0 == first }
    }

    private static func isAscendingSequence(_ raw: String) -> Bool {
        let digits = raw.compactMap { $0.wholeNumberValue }
        guard digits.count == raw.count, digits.count >= 2 else { return false }
        for i in 1..<digits.count where digits[i] != digits[i - 1] + 1 { return false }
        return true
    }

    private static func isDescendingSequence(_ raw: String) -> Bool {
        let digits = raw.compactMap { $0.wholeNumberValue }
        guard digits.count == raw.count, digits.count >= 2 else { return false }
        for i in 1..<digits.count where digits[i] != digits[i - 1] - 1 { return false }
        return true
    }
}
