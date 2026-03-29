import Foundation
@testable import PitchDreams

final class MockAPIClient: APIClientProtocol {
    var mockResult: Any?
    var mockError: Error?

    func loginParent(email: String, password: String) async throws -> TokenResponse {
        if let error = mockError { throw error }
        return mockResult as! TokenResponse
    }

    func loginChild(parentEmail: String, childNickname: String, pin: String) async throws -> TokenResponse {
        if let error = mockError { throw error }
        return mockResult as! TokenResponse
    }

    func refreshToken(_ token: String) async throws -> TokenResponse {
        if let error = mockError { throw error }
        return mockResult as! TokenResponse
    }

    func fetchChildren(token: String) async throws -> [ChildSummary] {
        if let error = mockError { throw error }
        return mockResult as! [ChildSummary]
    }
}
