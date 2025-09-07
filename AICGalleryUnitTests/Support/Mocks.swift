//
//  Mocks.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import SwiftData
import Testing
@testable import AICGallery

// MARK: - Mock Network

final class MockNetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    private var _isConnected: Bool
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    private let lock = NSLock()

    init(initial: Bool) { _isConnected = initial }

    var isConnected: Bool { lock.withLock { _isConnected } }

    func connectivityStream() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream<Bool>(bufferingPolicy: .bufferingNewest(8)) { cont in
            lock.withLock {
                continuations[id] = cont
                cont.yield(_isConnected) // immediate seed
            }
            cont.onTermination = { [weak self] _ in
                self?.lock.withLock { self?.continuations[id]?.finish(); self?.continuations[id] = nil }
            }
        }
    }

    func setConnected(_ new: Bool) {
        lock.withLock {
            guard _isConnected != new else { return }
            _isConnected = new
            for c in continuations.values { c.yield(new) }
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock(); defer { unlock() }
        return body()
    }
}

// MARK: - Mock API

final class FakeArtAPIClient: ArtAPIClientProtocol, @unchecked Sendable {
    var nextResult: ArtPageResult?
    var nextError: Error?

    func fetchArtworksPage(artistID: Int, page: Int, pageSize: Int) async throws -> ArtPageResult {
        if let err = nextError { throw err }
        if let res = nextResult { return res }
        throw URLError(.badServerResponse)
    }

    func iiifThumbnailURL(imageID: String, width: Int) -> URL {
        URL(string: "https://example.com/\(imageID)/\(width).jpg")!
    }

    func iiifDetailURL(imageID: String, width: Int) -> URL {
        URL(string: "https://example.com/\(imageID)/detail-\(width).jpg")!
    }
}

// MARK: - Test Event Bus (in-memory, synchronous)

actor TestEventBus: @preconcurrency ArtworkEventBusProtocol {
    private var continuations: [UUID: AsyncStream<ArtworkEvent>.Continuation] = [:]
    private(set) var posted: [ArtworkEvent] = []

    func stream() -> AsyncStream<ArtworkEvent> {
        let id = UUID()
        return AsyncStream<ArtworkEvent>(bufferingPolicy: .bufferingNewest(16)) { cont in
            continuations[id] = cont
            cont.onTermination = { [weak self] _ in
                Task { await self?.remove(id) }
            }
        }
    }

    func post(_ event: ArtworkEvent) {
        posted.append(event)
        for c in continuations.values { c.yield(event) }
    }

    private func remove(_ id: UUID) {
        continuations[id]?.finish()
        continuations[id] = nil
    }
}

// MARK: - In-memory SwiftData container

enum TestModelContainer {
    @MainActor
    static func make() throws -> (container: ModelContainer, context: ModelContext) {
        let schema = Schema([ArtworkRecord.self, PageRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        return (container, context)
    }
}

// MARK: - Builders

enum Fixtures {
    static func artItem(id: Int, title: String = "Title \(Int.random(in: 1...999))", imageID: String = "img\(Int.random(in: 1...999))", w: Int = 3000, h: Int = 2000) -> ArtSearchResponse.Item {
        .init(
            id: id,
            title: title,
            thumbnail: .init(lqip: nil, width: w, height: h, altText: nil),
            imageId: imageID,
            apiModel: nil,
            apiLink: nil,
            artistTitle: nil
        )
    }

    static func artPageResult(page: Int, count: Int, artistID: Int = 34946) -> ArtPageResult {
        let items = (0..<count).map { i in
            artItem(id: (page * 10_000) + i + 1)
        }
        return ArtPageResult(items: items, page: page, pageSize: count, totalPages: 999, totalItems: 999_999, iiifBase: "https://www.artic.edu/iiif/2")
    }

    static func domainPage(from result: ArtPageResult) -> Page<Artwork> {
        let mapped = result.items.compactMap { it -> Artwork? in
            guard let img = it.imageId else { return nil }
            return Artwork(
                id: it.id,
                title: it.title,
                artistID: 34946,
                imageID: img,
                thumbnailWidth: it.thumbnail?.width ?? 1,
                thumbnailHeight: it.thumbnail?.height ?? 1,
                thumbnailAltText: it.thumbnail?.altText
            )
        }
        return Page(items: mapped, page: result.page, pageSize: result.pageSize, totalPages: result.totalPages, totalItems: result.totalItems)
    }
}

// MARK: - Fake Repository (for ViewModel-focused tests)

final class FakeRepository: ArtworkRepositoryProtocol, @unchecked Sendable {
    var pages: [Int: Page<Artwork>] = [:]
    private(set) var calls: [(artist: Int, page: Int, size: Int)] = []

    func artworksPage(artistID: Int, page: Int, pageSize: Int, policy: CachePolicy) async throws -> Page<Artwork> {
        calls.append((artistID, page, pageSize))
        if let p = pages[page] { return p }
        throw DomainError.notFound
    }

    func warmRefreshParkedRequestsOnReconnect() async { /* no-op */ }
}
