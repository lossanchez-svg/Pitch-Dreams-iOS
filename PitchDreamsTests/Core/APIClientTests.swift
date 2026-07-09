import XCTest
@testable import PitchDreams

/// Serves canned responses for APIClientTests. Top-level (not nested in the
/// test case) and lock-guarded so nothing about its runtime registration or
/// concurrency checking can destabilize the test runner.
final class APIClientStubProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var _statusCode: Int = 200
    private static var _body: Data = Data("{}".utf8)

    /// statusCode < 0 simulates a transport-level failure.
    static func stub(status: Int, body: String = "{}") {
        lock.lock(); defer { lock.unlock() }
        _statusCode = status
        _body = Data(body.utf8)
    }

    private static func current() -> (Int, Data) {
        lock.lock(); defer { lock.unlock() }
        return (_statusCode, _body)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (statusCode, data) = Self.current()
        if statusCode < 0 {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Thread-safe flag for observing the onUnauthorized callback.
private final class CallbackFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var _fired = false
    var fired: Bool {
        lock.lock(); defer { lock.unlock() }
        return _fired
    }
    func set() {
        lock.lock(); defer { lock.unlock() }
        _fired = true
    }
}

/// Tests the real APIClient's transport behavior via a stubbed URLProtocol:
/// status-code mapping, the 401 → onUnauthorized wiring, and decode failures.
final class APIClientTests: XCTestCase {

    private struct PingResponse: Decodable, Equatable {
        let ok: Bool
    }

    private struct TestEndpoint: APIEndpoint {
        var path: String { "/ping" }
        var method: HTTPMethod { .get }
        var requiresAuth: Bool { false }
    }

    private var client: APIClient!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [APIClientStubProtocol.self]
        client = APIClient(session: URLSession(configuration: config))
        APIClientStubProtocol.stub(status: 200)
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    // MARK: - Success path

    func testSuccessDecodesResponse() async throws {
        APIClientStubProtocol.stub(status: 200, body: #"{"ok":true}"#)
        let result: PingResponse = try await client.request(TestEndpoint())
        XCTAssertEqual(result, PingResponse(ok: true))
    }

    // MARK: - 401 handling (the silent-brick regression)

    func testUnauthorizedThrowsAndFiresHandler() async {
        APIClientStubProtocol.stub(status: 401)
        let flag = CallbackFlag()
        client.onUnauthorized = { flag.set() }

        do {
            let _: PingResponse = try await client.request(TestEndpoint())
            XCTFail("Expected APIError.unauthorized")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                return XCTFail("Expected .unauthorized, got \(error)")
            }
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }

        XCTAssertTrue(flag.fired, "onUnauthorized must fire on 401")
    }

    func testUnauthorizedOnVoidRequestFiresHandler() async {
        APIClientStubProtocol.stub(status: 401)
        let flag = CallbackFlag()
        client.onUnauthorized = { flag.set() }

        do {
            try await client.requestVoid(TestEndpoint())
            XCTFail("Expected APIError.unauthorized")
        } catch {}

        XCTAssertTrue(flag.fired)
    }

    func testSuccessDoesNotFireUnauthorizedHandler() async throws {
        APIClientStubProtocol.stub(status: 200, body: #"{"ok":true}"#)
        let flag = CallbackFlag()
        client.onUnauthorized = { flag.set() }
        let _: PingResponse = try await client.request(TestEndpoint())
        XCTAssertFalse(flag.fired)
    }

    // MARK: - Status-code mapping

    func testServerErrorMapsTo5xxCase() async {
        APIClientStubProtocol.stub(status: 500, body: #"{"error":"boom"}"#)
        await assertThrows { error in
            guard case .server(let msg) = error else { return XCTFail("Expected .server, got \(error)") }
            XCTAssertEqual(msg, "boom")
        }
    }

    func testValidationErrorMapsTo400() async {
        APIClientStubProtocol.stub(status: 400, body: #"{"error":"bad input"}"#)
        await assertThrows { error in
            guard case .validation(let msg) = error else { return XCTFail("Expected .validation, got \(error)") }
            XCTAssertEqual(msg, "bad input")
        }
    }

    func testForbiddenMapsTo403() async {
        APIClientStubProtocol.stub(status: 403)
        await assertThrows { error in
            guard case .forbidden = error else { return XCTFail("Expected .forbidden, got \(error)") }
        }
    }

    func testNotFoundMapsTo404() async {
        APIClientStubProtocol.stub(status: 404)
        await assertThrows { error in
            guard case .notFound = error else { return XCTFail("Expected .notFound, got \(error)") }
        }
    }

    func testConflictMapsTo409() async {
        APIClientStubProtocol.stub(status: 409)
        await assertThrows { error in
            guard case .conflict = error else { return XCTFail("Expected .conflict, got \(error)") }
        }
    }

    func testUnexpectedStatusMapsToUnknown() async {
        APIClientStubProtocol.stub(status: 418)
        await assertThrows { error in
            guard case .unknown(let code, _) = error else { return XCTFail("Expected .unknown, got \(error)") }
            XCTAssertEqual(code, 418)
        }
    }

    // MARK: - Transport + decode failures

    func testTransportFailureMapsToNetworkError() async {
        APIClientStubProtocol.stub(status: -1)
        await assertThrows { error in
            guard case .network = error else { return XCTFail("Expected .network, got \(error)") }
        }
    }

    func testMalformedBodyMapsToDecodingError() async {
        APIClientStubProtocol.stub(status: 200, body: #"{"unexpected":"shape"}"#)
        await assertThrows { error in
            guard case .decoding = error else { return XCTFail("Expected .decoding, got \(error)") }
        }
    }

    // MARK: - Helper

    private func assertThrows(
        file: StaticString = #filePath,
        line: UInt = #line,
        verify: (APIError) -> Void
    ) async {
        do {
            let _: PingResponse = try await client.request(TestEndpoint())
            XCTFail("Expected error", file: file, line: line)
        } catch let error as APIError {
            verify(error)
        } catch {
            XCTFail("Expected APIError, got \(error)", file: file, line: line)
        }
    }
}
