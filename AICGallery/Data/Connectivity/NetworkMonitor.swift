//
//  NetworkMonitor.swift
//  AICGallery
//

import Foundation
import Network

protocol NetworkMonitorProtocol: AnyObject, Sendable {
    var isConnected: Bool { get }
    /// Each call returns a fresh stream that:
    /// 1) immediately yields the current state
    /// 2) then yields subsequent connectivity flips (both directions)
    func connectivityStream() -> AsyncStream<Bool>
}

final class NetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "net.monitor.serial")

    // Guarded by `queue`
    private var _isConnected: Bool
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    private var isShuttingDown = false

    var isConnected: Bool {
        // Read the canonical state we maintain (don’t rely on currentPath off-queue)
        var snapshot = false
        queue.sync { snapshot = _isConnected }
        return snapshot
    }

    init() {
        // Seed from current path synchronously to avoid a blank initial state
        _isConnected = (monitor.currentPath.status == .satisfied)

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newValue = (path.status == .satisfied)
            self.queue.async {
                guard !self.isShuttingDown else { return }
                if self._isConnected != newValue {
                    self._isConnected = newValue
                    for c in self.continuations.values { c.yield(newValue) }
                }
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        queue.sync {
            isShuttingDown = true
            for c in continuations.values { c.finish() }
            continuations.removeAll()
        }
        monitor.cancel()
    }

    func connectivityStream() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream<Bool>(bufferingPolicy: .bufferingNewest(1)) { [weak self] cont in
            guard let self else { return }
            queue.async {
                guard !self.isShuttingDown else { cont.finish(); return }
                self.continuations[id] = cont
                // Emit current value immediately
                cont.yield(self._isConnected)
            }
            cont.onTermination = { [weak self] _ in
                guard let self else { return }
                self.queue.async {
                    self.continuations[id]?.finish()
                    self.continuations[id] = nil
                }
            }
        }
    }
}
