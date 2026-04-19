import XCTest
@testable import PitchDreams

final class InputValidatorTests: XCTestCase {

    // MARK: - Email

    func testEmail_acceptsCommonFormats() {
        XCTAssertNil(InputValidator.email("alex@example.com"))
        XCTAssertNil(InputValidator.email("ALEX.SMITH@domain.co.uk"))
        XCTAssertNil(InputValidator.email("user+tag@sub.example.com"))
    }

    func testEmail_rejectsMissingAtOrDot() {
        XCTAssertNotNil(InputValidator.email("no-at-sign.com"))
        XCTAssertNotNil(InputValidator.email("no-dot@domain"))
        XCTAssertNotNil(InputValidator.email("a@b.c"))  // 1-char TLD
    }

    func testEmail_silentWhileEmpty() {
        XCTAssertNil(InputValidator.email(""))
        XCTAssertNil(InputValidator.email("   "))
    }

    // MARK: - Password

    func testPassword_shortRejected() {
        XCTAssertEqual(InputValidator.password("abc1"), "At least 8 characters.")
    }

    func testPassword_missingLetter() {
        XCTAssertEqual(InputValidator.password("12345678"), "Include at least one letter.")
    }

    func testPassword_missingNumber() {
        XCTAssertEqual(InputValidator.password("abcdefgh"), "Include at least one number.")
    }

    func testPassword_accepts() {
        XCTAssertNil(InputValidator.password("letters8digits"))
    }

    func testPasswordStrength_scales() {
        XCTAssertEqual(InputValidator.passwordStrength(""), 0)
        XCTAssertLessThanOrEqual(InputValidator.passwordStrength("short"), 1)
        XCTAssertGreaterThanOrEqual(InputValidator.passwordStrength("longerpass99"), 2)
        XCTAssertEqual(InputValidator.passwordStrength("thisisagoodlongpassword99"), 3)
    }

    func testPasswordsMatch() {
        XCTAssertNil(InputValidator.passwordsMatch("a", "a"))
        XCTAssertNotNil(InputValidator.passwordsMatch("a", "b"))
        XCTAssertNil(InputValidator.passwordsMatch("a", ""))  // empty confirm doesn't nag
    }

    // MARK: - PIN

    func testPin_rejectsNonDigits() {
        XCTAssertEqual(InputValidator.pin("12a4"), "Numbers only.")
    }

    func testPin_tooShort() {
        XCTAssertEqual(InputValidator.pin("123"), "PIN must be 4 digits.")
    }

    func testPin_tooLong() {
        XCTAssertEqual(InputValidator.pin("1234567"), "PIN can't be more than 6 digits.")
    }

    func testPin_banned0000() {
        XCTAssertEqual(InputValidator.pin("0000"), "Pick something less obvious.")
    }

    func testPin_banned1234() {
        XCTAssertNotNil(InputValidator.pin("1234"))
    }

    func testPin_banned111111() {
        XCTAssertNotNil(InputValidator.pin("111111"))
    }

    func testPin_rejectsAllSame() {
        XCTAssertEqual(InputValidator.pin("7777"), "Pick something less obvious.")
    }

    func testPin_rejectsAscending() {
        XCTAssertNotNil(InputValidator.pin("2345"))
        XCTAssertNotNil(InputValidator.pin("456789"))
    }

    func testPin_rejectsDescending() {
        XCTAssertNotNil(InputValidator.pin("8765"))
    }

    func testPin_acceptsReasonable() {
        XCTAssertNil(InputValidator.pin("7392"))
        XCTAssertNil(InputValidator.pin("483716"))
    }

    // MARK: - Nickname

    func testNickname_acceptsCommon() {
        XCTAssertNil(InputValidator.nickname("Alex"))
        XCTAssertNil(InputValidator.nickname("Alex9"))
        XCTAssertNil(InputValidator.nickname("Star_Kid"))
        XCTAssertNil(InputValidator.nickname("Rain-Maker"))
    }

    func testNickname_tooShort() {
        XCTAssertEqual(InputValidator.nickname("a"), "At least 2 characters.")
    }

    func testNickname_tooLong() {
        XCTAssertEqual(InputValidator.nickname(String(repeating: "a", count: 21)), "Max 20 characters.")
    }

    func testNickname_rejectsUnsupportedChars() {
        XCTAssertNotNil(InputValidator.nickname("Alex@Home"))
        XCTAssertNotNil(InputValidator.nickname("😀🎉"))
    }

    func testNickname_rejectsProfanity() {
        XCTAssertEqual(InputValidator.nickname("bigDickPlayer"), "Pick a different nickname.")
    }

    func testNickname_silentWhileEmpty() {
        XCTAssertNil(InputValidator.nickname(""))
        XCTAssertNil(InputValidator.nickname("  "))
    }
}
