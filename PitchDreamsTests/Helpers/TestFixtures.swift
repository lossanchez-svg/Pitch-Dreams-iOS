import Foundation
@testable import PitchDreams

enum TestFixtures {

    // MARK: - Authenticated Users

    static func parentUser(
        id: String = "parent-123",
        email: String = "parent@example.com",
        name: String = "Test Parent"
    ) -> AuthenticatedUser {
        AuthenticatedUser(
            id: id,
            email: email,
            name: name,
            role: .parent,
            childId: nil
        )
    }

    static func childUser(
        id: String = "child-456",
        name: String = "Test Child",
        childId: String = "child-456",
        parentEmail: String = "parent@example.com"
    ) -> AuthenticatedUser {
        AuthenticatedUser(
            id: id,
            email: parentEmail,
            name: name,
            role: .child,
            childId: childId
        )
    }

    // MARK: - Token Responses

    static func tokenResponse(
        accessToken: String = "test-access-token",
        refreshToken: String = "test-refresh-token",
        expiresIn: Int = 3600,
        user: AuthenticatedUser? = nil
    ) -> TokenResponse {
        TokenResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            user: user ?? parentUser()
        )
    }

    // MARK: - Child Summaries

    static func childSummary(
        id: String = "child-456",
        nickname: String = "TestKid",
        age: Int = 12
    ) -> ChildSummary {
        ChildSummary(
            id: id,
            nickname: nickname,
            age: age
        )
    }

    static func childSummaries(count: Int = 2) -> [ChildSummary] {
        (0..<count).map { i in
            ChildSummary(
                id: "child-\(i)",
                nickname: "Kid\(i)",
                age: 10 + i
            )
        }
    }
}
