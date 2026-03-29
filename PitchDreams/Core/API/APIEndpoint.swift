import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var body: (any Encodable)? { get }
    var requiresAuth: Bool { get }
}

extension APIEndpoint {
    var queryItems: [URLQueryItem]? { nil }
    var body: (any Encodable)? { nil }
    var requiresAuth: Bool { true }
}
