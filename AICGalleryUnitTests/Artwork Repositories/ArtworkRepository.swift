//
//  RepositoryTests.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import SwiftData
import Testing
@testable import AICGallery

@Suite("ArtworkRepository")
struct RepositoryTests {

    @MainActor
    @Test("Online + stale → fetch, upsert, event")
    func onlineFetchUpsertEvent() async throws {
        let (_, ctx) = try TestModelContainer.make()

        let api = FakeArtAPIClient()
        api.nextResult = Fixtures.artPageResult(page: 1, count: 3)

        let net = MockNetworkMonitor(initial: true)
        let bus = ArtworkEventBus()
        let repo = ArtworkRepository(api: api, modelContext: ctx, network: net, events: bus)

        // Start collecting events
        let collector = EventCollector()
        await collector.start(bus: bus)

        // Force "stale" so repo hits the network and upserts
        let page = try await repo.artworksPage(
            artistID: 34946,
            page: 1,
            pageSize: 20,
            policy: CachePolicy(pageTTL: 0)
        )
        #expect(page.items.count == 3)

        // Ask again with a very long TTL; should hit cache
        let cached = try await repo.artworksPage(
            artistID: 34946,
            page: 1,
            pageSize: 20,
            policy: CachePolicy(pageTTL: 3_600)
        )
        #expect(cached.items.count == 3)

        // Event should have been posted
        try await TestWait.short()
        #expect(await collector.containsUpdated(artistID: 34946, page: 1))

        await collector.stop()
    }

    @MainActor
    @Test("Offline + cache → returns cache and parks; reconnect drains & posts event")
    func offlineCacheThenDrain() async throws {
        let (_, ctx) = try TestModelContainer.make()

        let api = FakeArtAPIClient()
        let net = MockNetworkMonitor(initial: false) // start offline
        let bus = ArtworkEventBus()
        let repo = ArtworkRepository(api: api, modelContext: ctx, network: net, events: bus)

        let collector = EventCollector()
        await collector.start(bus: bus)

        // Seed cache by going online briefly and fetching page 2
        net.setConnected(true)
        api.nextResult = Fixtures.artPageResult(page: 2, count: 2)
        _ = try await repo.artworksPage(
            artistID: 34946,
            page: 2,
            pageSize: 20,
            policy: CachePolicy(pageTTL: 0) // network path
        )

        // Go offline: request page 2 → should return cache (no throw), park refresh
        net.setConnected(false)
        let cached = try await repo.artworksPage(
            artistID: 34946,
            page: 2,
            pageSize: 20,
            policy: CachePolicy(pageTTL: 0) // stale but offline
        )
        #expect(cached.items.count == 2)

        // Prepare fresher server result and reconnect → repo drains parked requests
        api.nextResult = Fixtures.artPageResult(page: 2, count: 3)
        net.setConnected(true)

        // Give the background connectivity task time to call warmRefresh…
        try await TestWait.medium()

        // Expect pageUpdated(artistID:34946,page:2) posted
        #expect(await collector.containsUpdated(artistID: 34946, page: 2))

        await collector.stop()
    }
    
    @MainActor
    @Test("Offline + empty store → .offlineNoCache")
    func offlineNoCacheThrows() async throws {
        let (_, ctx) = try TestModelContainer.make()
        let api = FakeArtAPIClient()
        let net = MockNetworkMonitor(initial: false) // offline
        let bus = ArtworkEventBus()

        let repo = ArtworkRepository(api: api, modelContext: ctx, network: net, events: bus)

        do {
            _ = try await repo.artworksPage(artistID: 34946, page: 1, pageSize: 20, policy: CachePolicy(pageTTL: 0))
            Issue.record("Expected to throw .offlineNoCache, but succeeded")
        } catch let err as DomainError {
            #expect(err == .offlineNoCache)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
