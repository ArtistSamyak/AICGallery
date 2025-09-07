//
//  SpyAPI.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import SwiftData
import Testing
@testable import AICGallery

private final class SpyAPI: ArtAPIClientProtocol, @unchecked Sendable {
    var calls: [(artist: Int, page: Int, size: Int)] = []
    var result: ArtPageResult?

    func fetchArtworksPage(artistID: Int, page: Int, pageSize: Int) async throws -> ArtPageResult {
        calls.append((artistID, page, pageSize))
        guard let result else { throw URLError(.badServerResponse) }
        return result
    }
    func iiifThumbnailURL(imageID: String, width: Int) -> URL { URL(string:"https://x/\(imageID)/\(width)")! }
    func iiifDetailURL(imageID: String, width: Int) -> URL { URL(string:"https://x/\(imageID)/d\(width)")! }
}

@Suite("ArtworkRepository TTL")
struct RepositoryTTLTests {

    @MainActor
    @Test("Fresh TTL returns cache without hitting API again")
    func freshTTLSkipsNetwork() async throws {
        let (_, ctx) = try TestModelContainer.make()
        let api = SpyAPI()
        let net = MockNetworkMonitor(initial: true)
        let bus = ArtworkEventBus()
        let repo = ArtworkRepository(api: api, modelContext: ctx, network: net, events: bus)

        // First call with TTL=0 -> network
        api.result = Fixtures.artPageResult(page: 1, count: 2)
        _ = try await repo.artworksPage(artistID: 34946, page: 1, pageSize: 20, policy: CachePolicy(pageTTL: 0))
        #expect(api.calls.count == 1)

        // Second call with large TTL should use cache and not call API
        _ = try await repo.artworksPage(artistID: 34946, page: 1, pageSize: 20, policy: CachePolicy(pageTTL: 3_600))
        #expect(api.calls.count == 1, "API should not be called again while TTL fresh")
    }
}
