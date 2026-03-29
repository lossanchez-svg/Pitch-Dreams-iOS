import Foundation
@testable import PitchDreams

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var responses: [Any] = []
    var errors: [Error?] = []
    var calledEndpoints: [String] = []
    private var callIndex = 0
    private let lock = NSLock()

    func enqueue<T: Decodable>(_ response: T) {
        responses.append(response)
        errors.append(nil)
    }

    func enqueueError(_ error: Error) {
        responses.append(0)  // placeholder
        errors.append(error)
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        lock.lock()
        calledEndpoints.append(endpoint.path)
        guard callIndex < responses.count else {
            let idx = callIndex
            lock.unlock()
            throw APIError.unknown(0, "No mock response queued for call \(idx)")
        }
        let idx = callIndex
        callIndex += 1
        lock.unlock()

        if let error = errors[idx] { throw error }
        guard let response = responses[idx] as? T else {
            throw APIError.decoding(NSError(domain: "MockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Type mismatch at index \(idx): expected \(T.self), got \(type(of: responses[idx]))"]))
        }
        return response
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        lock.lock()
        calledEndpoints.append(endpoint.path)
        guard callIndex < errors.count else {
            lock.unlock()
            return
        }
        let idx = callIndex
        callIndex += 1
        lock.unlock()

        if let error = errors[idx] { throw error }
    }

    func reset() {
        lock.lock()
        responses.removeAll()
        errors.removeAll()
        calledEndpoints.removeAll()
        callIndex = 0
        lock.unlock()
    }
}
