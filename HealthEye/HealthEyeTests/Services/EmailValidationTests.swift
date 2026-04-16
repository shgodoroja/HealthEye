import Testing
import Foundation
@testable import HealthEye

struct EmailValidationTests {

    // Use the same regex pattern from WelcomeView
    private static let emailRegex = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/

    private func isValid(_ email: String) -> Bool {
        (try? Self.emailRegex.wholeMatch(in: email)) != nil
    }

    // MARK: - Valid emails

    @Test func validStandardEmail() {
        #expect(isValid("coach@example.com"))
    }

    @Test func validEmailWithSubdomain() {
        #expect(isValid("user@mail.example.com"))
    }

    @Test func validEmailWithPlus() {
        #expect(isValid("coach+tag@example.com"))
    }

    @Test func validEmailWithDots() {
        #expect(isValid("first.last@example.com"))
    }

    @Test func validEmailWithHyphens() {
        #expect(isValid("user@my-domain.com"))
    }

    // MARK: - Invalid emails

    @Test func rejectsEmpty() {
        #expect(!isValid(""))
    }

    @Test func rejectsMissingAt() {
        #expect(!isValid("coachexample.com"))
    }

    @Test func rejectsMissingDomain() {
        #expect(!isValid("coach@"))
    }

    @Test func rejectsMissingTLD() {
        #expect(!isValid("coach@example"))
    }

    @Test func rejectsSingleCharTLD() {
        #expect(!isValid("coach@example.c"))
    }

    @Test func rejectsSpaces() {
        #expect(!isValid("coach @example.com"))
    }

    @Test func rejectsDoubleAt() {
        #expect(!isValid("coach@@example.com"))
    }

    @Test func rejectsJustAtAndDot() {
        #expect(!isValid("@."))
    }
}
