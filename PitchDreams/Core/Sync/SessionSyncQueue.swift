import Foundation

/// Queues session-save requests that failed due to transient network errors
/// and retries them on app foreground + when connectivity returns.
///
/// The queue is the "no-data-lost" guarantee behind the optimistic UI on
/// session-save screens: the ViewModel shows success as soon as the request
/// is either delivered to the server or durably enqueued here.
///
/// Persistence: UserDefaults (JSON-encoded `[Entry]`), keyed globally — a
/// single child's data is identified per-entry, so a multi-profile device
/// simply accumulates its entries side-by-side.
actor SessionSyncQueue {

    // MARK: - Types

    enum Kind: String, Codable {
        case session
        case quickSession
    }

    /// One pending request. Self-contained so the queue can rebuild the
    /// APIRouter case on flush without any external lookup.
    struct Entry: Codable, Identifiable, Equatable {
        let id: UUID
        let kind: Kind
        let childId: String
        /// JSON-encoded body — stored as Data so body structs don't need to
        /// round-trip through a common wrapper type.
        let bodyData: Data
        let createdAt: Date
        var attempts: Int
    }

    enum FlushOutcome: Equatable {
        /// All pending entries succeeded (or the queue was empty).
        case drained
        /// Some entries remain — either from transient errors or queue was
        /// partial. The caller may retry on the next app foreground.
        case partial(remaining: Int)
    }

    // MARK: - Shared

    static let shared = SessionSyncQueue()

    // MARK: - State

    private let defaults: UserDefaults
    private let storageKey = "session_sync_queue_v1"
    private let maxAttempts = 6
    private let apiClient: APIClientProtocol

    init(
        defaults: UserDefaults = .standard,
        apiClient: APIClientProtocol = APIClient()
    ) {
        self.defaults = defaults
        self.apiClient = apiClient
    }

    // MARK: - Public

    /// Enqueue a session-save body for later retry. Returns the new entry.
    @discardableResult
    func enqueueSession(childId: String, body: CreateSessionBody) -> Entry {
        enqueue(kind: .session, childId: childId, body: body)
    }

    /// Enqueue a quick-log body for later retry.
    @discardableResult
    func enqueueQuickSession(childId: String, body: QuickSessionBody) -> Entry {
        enqueue(kind: .quickSession, childId: childId, body: body)
    }

    /// Current pending count. Useful for a "syncing…" badge in the UI.
    func pendingCount() -> Int {
        load().count
    }

    /// Attempt to flush all pending entries. Call on app foreground and when
    /// the network reconnects. Entries that fail with a network error are
    /// retained for the next attempt; entries that fail persistently (4xx,
    /// decoding, repeated attempts past `maxAttempts`) are dropped so the
    /// queue can't grow forever.
    @discardableResult
    func flush() async -> FlushOutcome {
        var pending = load()
        guard !pending.isEmpty else { return .drained }

        var remaining: [Entry] = []
        for entry in pending {
            let result = await send(entry)
            switch result {
            case .delivered:
                continue  // drop from queue
            case .retryLater(let updated):
                remaining.append(updated)
            case .permanentFailure:
                continue  // drop — we can't recover this one
            }
        }
        pending = remaining
        save(pending)
        return pending.isEmpty ? .drained : .partial(remaining: pending.count)
    }

    /// Drop everything. Intended for logout / "reset progress" flows.
    func clear() {
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: - Private

    private enum SendResult {
        case delivered
        case retryLater(Entry)
        case permanentFailure
    }

    private func enqueue<Body: Encodable>(kind: Kind, childId: String, body: Body) -> Entry {
        let data = (try? JSONEncoder().encode(body)) ?? Data()
        let entry = Entry(
            id: UUID(),
            kind: kind,
            childId: childId,
            bodyData: data,
            createdAt: Date(),
            attempts: 0
        )
        var pending = load()
        pending.append(entry)
        save(pending)
        return entry
    }

    private func send(_ entry: Entry) async -> SendResult {
        guard entry.attempts < maxAttempts else { return .permanentFailure }

        do {
            switch entry.kind {
            case .session:
                let body = try JSONDecoder().decode(CreateSessionBody.self, from: entry.bodyData)
                let _: SessionSaveResult = try await apiClient.request(
                    APIRouter.createSession(childId: entry.childId, body: body)
                )
            case .quickSession:
                let body = try JSONDecoder().decode(QuickSessionBody.self, from: entry.bodyData)
                let _: SessionSaveResult = try await apiClient.request(
                    APIRouter.createQuickSession(childId: entry.childId, body: body)
                )
            }
            return .delivered
        } catch APIError.network {
            var updated = entry
            updated.attempts += 1
            return .retryLater(updated)
        } catch APIError.unauthorized {
            // Hold — caller is logged out. Retry on next flush after reauth.
            var updated = entry
            updated.attempts += 1
            return .retryLater(updated)
        } catch {
            // 4xx / 5xx / decoding — the server has rejected this payload.
            // Dropping is safer than retrying a request the server won't accept.
            Log.api.error("SessionSyncQueue dropping unrecoverable entry \(entry.id) kind=\(entry.kind.rawValue): \(error)")
            return .permanentFailure
        }
    }

    private func load() -> [Entry] {
        guard let data = defaults.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return entries
    }

    private func save(_ entries: [Entry]) {
        if entries.isEmpty {
            defaults.removeObject(forKey: storageKey)
            return
        }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
