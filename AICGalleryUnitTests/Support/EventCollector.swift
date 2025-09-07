//
//  EventCollector.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
@testable import AICGallery

/// Subscribes to ArtworkEventBus and collects events for assertions.
actor EventCollector {
    private var events: [ArtworkEvent] = []
    private var task: Task<Void, Never>?

    /// Begin listening to the concrete bus.
    func start(bus: ArtworkEventBus) async {
        let stream = await bus.stream()
        task = Task {
            for await e in stream {
                await self.record(e)
            }
        }
    }

    /// Stop listening.
    func stop() {
        task?.cancel()
        task = nil
    }

    /// Make this async to satisfy the await at call site (and silence the warning).
    private func record(_ e: ArtworkEvent) async {
        events.append(e)
    }

    /// Snapshot of all events so far.
    func all() -> [ArtworkEvent] { events }

    /// Convenience matcher for assertions.
    func containsUpdated(artistID: Int, page: Int) -> Bool {
        events.contains {
            if case let .pageUpdated(a, p) = $0 { return a == artistID && p == page }
            return false
        }
    }
}
