import Foundation

struct TokenInterceptor {
    private let keychain: KeychainServiceProtocol

    init(keychain: KeychainServiceProtocol = KeychainService()) {
        self.keychain = keychain
    }

    func intercept(_ request: inout URLRequest) {
        guard let token = keychain.retrieve(for: Constants.Keychain.tokenKey) else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
