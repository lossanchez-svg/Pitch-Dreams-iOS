import Foundation

/// Server error response shape: `{ "error": "message" }`
struct ServerError: Decodable {
    let error: String
}

enum APIError: LocalizedError {
    case network(URLError)
    case unauthorized
    case forbidden(String)
    case notFound
    case validation(String)
    case conflict(String)
    case server(String)
    case decoding(Error)
    case unknown(Int, String?)

    var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .unauthorized: return "Please log in again"
        case .forbidden(let msg): return msg
        case .notFound: return "Not found"
        case .validation(let msg): return msg
        case .conflict(let msg): return msg
        case .server(let msg): return msg
        case .decoding: return "Failed to process server response"
        case .unknown(_, let msg): return msg ?? "Something went wrong"
        }
    }
}
