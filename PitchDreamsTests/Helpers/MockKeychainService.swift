import Foundation
@testable import PitchDreams

final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var store: [String: String] = [:]

    func save(value: String, for key: String) throws {
        store[key] = value
    }

    func retrieve(for key: String) -> String? {
        return store[key]
    }

    func delete(for key: String) throws {
        store.removeValue(forKey: key)
    }

    func clear() {
        store.removeAll()
    }
}
