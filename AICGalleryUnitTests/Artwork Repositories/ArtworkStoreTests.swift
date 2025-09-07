//
//  ArtworkStoreTests.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import SwiftData
import Testing
@testable import AICGallery

@Suite("ArtworkStore")
struct ArtworkStoreTests {

    @MainActor
    @Test("upsert → fetch → meta → refreshedAt")
    func upsertFetchMeta() async throws {
        let (_, ctx) = try TestModelContainer.make()
        let store = ArtworkStore(modelContext: ctx)

        let artistID = 34946
        let artistKey = ArtworkStore.artistKey(for: artistID)

        // Upsert page 1 with 3 items
        let res1 = Fixtures.artPageResult(page: 1, count: 3)
        try store.upsert(pageResult: res1, artistKey: artistKey)

        // Fetch them back
        let items1 = try store.artworks(artistKey: artistKey, page: 1)
        #expect(items1.count == 3)

        // Meta should reflect count
        let meta1 = try store.meta(artistKey: artistKey, page: 1, fallbackPageSize: 20)
        #expect(meta1.pageSize == 3)
        #expect(meta1.totalItems == 3)

        // TTL timestamp should be recent (not distantPast)
        let ts1 = try store.pageRefreshedAt(artistKey: artistKey, page: 1)
        #expect(ts1.timeIntervalSinceNow > -2.0)

        // Upsert again with 4 items (simulate new page data)
        let res2 = Fixtures.artPageResult(page: 1, count: 4)
        try store.upsert(pageResult: res2, artistKey: artistKey)

        let items2 = try store.artworks(artistKey: artistKey, page: 1)
        #expect(items2.count == 4)

        let meta2 = try store.meta(artistKey: artistKey, page: 1, fallbackPageSize: 20)
        #expect(meta2.pageSize == 4)
        #expect(meta2.totalItems == 4)

        let ts2 = try store.pageRefreshedAt(artistKey: artistKey, page: 1)
        #expect(ts2 >= ts1)
    }
}
