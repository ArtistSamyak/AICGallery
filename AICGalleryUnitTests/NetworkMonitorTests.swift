//
//  NetworkMonitorTests.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import Testing
@testable import AICGallery

@Suite("MockNetworkMonitor")
struct NetworkMonitorTests {
    @Test
    func emitsInitialAndFlips() async throws {
        let net = MockNetworkMonitor(initial: true)
        var events: [Bool] = []

        let task = Task {
            for await v in net.connectivityStream() {
                events.append(v)
                if events.count >= 3 { break }
            }
        }

        // initial true
        try await TestWait.short()
        net.setConnected(false) // flip to offline
        try await TestWait.short()
        net.setConnected(true)  // flip to online
        try await TestWait.short()

        _ = await task.result

        // Expect: true (seed), false, true
        #expect(events.prefix(3) == [true, false, true])
    }
}
