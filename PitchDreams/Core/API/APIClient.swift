import Foundation

protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func requestVoid(_ endpoint: APIEndpoint) async throws
}

final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL: URL
    private let interceptor: TokenInterceptor
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Called on 401 — AuthManager sets this to trigger logout
    var onUnauthorized: (@Sendable () -> Void)?

    init(
        session: URLSession = .shared,
        baseURL: URL = Constants.baseURL,
        interceptor: TokenInterceptor = TokenInterceptor()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.interceptor = interceptor

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let (data, _) = try await performRequest(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let bodyPreview = String(data: data.prefix(500), encoding: .utf8) ?? "<non-utf8>"
            Log.api.error("Decode \(String(describing: T.self)) failed: \(error)\nBody: \(bodyPreview)")
            throw APIError.decoding(error)
        }
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let _ = try await performRequest(endpoint)
    }

    // MARK: - Private

    private func performRequest(_ endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.apiBasePath + endpoint.path), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = endpoint.queryItems

        guard let url = urlComponents.url else {
            throw APIError.unknown(0, "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if endpoint.requiresAuth {
            interceptor.intercept(&request)
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        Log.api.debug("\(endpoint.method.rawValue) \(endpoint.path)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(0, "Invalid response")
        }

        try mapStatusCode(httpResponse.statusCode, data: data)
        return (data, httpResponse)
    }

    private func mapStatusCode(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            onUnauthorized?()
            throw APIError.unauthorized
        case 403:
            let msg = parseErrorMessage(data)
            throw APIError.forbidden(msg ?? "Access denied")
        case 404:
            let msg = parseErrorMessage(data)
            throw APIError.notFound(msg ?? "Not found")
        case 400:
            let msg = parseErrorMessage(data)
            throw APIError.validation(msg ?? "Invalid input")
        case 409:
            let msg = parseErrorMessage(data)
            throw APIError.conflict(msg ?? "Conflict")
        case 500...599:
            let msg = parseErrorMessage(data)
            throw APIError.server(msg ?? "Server error")
        default:
            let msg = parseErrorMessage(data)
            throw APIError.unknown(statusCode, msg)
        }
    }

    private func parseErrorMessage(_ data: Data) -> String? {
        try? decoder.decode(ServerError.self, from: data).error
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encode = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
