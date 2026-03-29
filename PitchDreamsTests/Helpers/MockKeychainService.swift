import Foundation
@testable import PitchDreams

final class MockKeychainService: KeychainServiceProtocol {
    private var store: [String: String] = [:]

    func save(_ value: String, forKey key: String) throws {
        store[key] = value
    }

    func load(forKey key: String) throws -> String? {
        return store[key]
    }

    func delete(forKey key: String) throws {
        store.removeValue(forKey: key)
    }

    func deleteAll() throws {
        store.removeAll()
    }
}
