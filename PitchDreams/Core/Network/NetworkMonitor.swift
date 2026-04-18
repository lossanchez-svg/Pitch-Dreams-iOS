import Foundation
import Network

/// Observable network-reachability state for the UI.
///
/// Backed by `NWPathMonitor`. Owns a dedicated serial queue for path updates
/// and republishes status on the main actor so SwiftUI views can observe it
/// directly via `@EnvironmentObject`.
///
/// Use `shared` from the app lifecycle — a single monitor per process is
/// sufficient, and `NWPathMonitor` is stateful.
@MainActor
final class NetworkMonitor: ObservableObject {
    enum Status: Equatable {
        case unknown
        case online(ConnectionType)
        case offline

        var isOnline: Bool {
            if case .online = self { return true }
            return false
        }
    }

    enum ConnectionType: Equatable {
        case wifi
        case cellular
        case wired
        case other
    }

    static let shared = NetworkMonitor()

    @Published private(set) var status: Status = .unknown

    /// Fires each time the path transitions from offline to online.
    /// Consumers (retry queues) can observe this without polling.
    @Published private(set) var reconnectedAt: Date?

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.pitchdreams.networkmonitor", qos: .utility)
    private var hasStarted = false

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
    }

    /// Call once at app launch. Idempotent.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newStatus = Self.mapStatus(path)
            Task { @MainActor in
                self.apply(newStatus)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        hasStarted = false
    }

    // MARK: - Private

    private func apply(_ newStatus: Status) {
        let wasOffline = status == .offline
        status = newStatus
        if wasOffline, newStatus.isOnline {
            reconnectedAt = Date()
        }
    }

    private static func mapStatus(_ path: NWPath) -> Status {
        guard path.status == .satisfied else { return .offline }
        let type: ConnectionType
        if path.usesInterfaceType(.wifi) {
            type = .wifi
        } else if path.usesInterfaceType(.cellular) {
            type = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            type = .wired
        } else {
            type = .other
        }
        return .online(type)
    }
}
