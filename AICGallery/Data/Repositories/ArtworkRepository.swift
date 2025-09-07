//
//  ArtworkRepository.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation
import SwiftData

public final class ArtworkRepository: ArtworkRepositoryProtocol, @unchecked Sendable {
    
    private let api: ArtAPIClientProtocol
    private let store: ArtworkStore
    private let queue: ParkedRequestQueue
    private let network: NetworkMonitorProtocol
    private let events: ArtworkEventBus
    
    private var connectivityTask: Task<Void, Never>?
    
    // MARK: - Init
    
    @MainActor
    init(
        api: ArtAPIClientProtocol,
        modelContext: ModelContext,
        network: NetworkMonitorProtocol,
        events: ArtworkEventBus
    ) {
        self.api = api
        self.store = ArtworkStore(modelContext: modelContext)
        self.queue = ParkedRequestQueue()
        self.network = network
        self.events = events
        
        connectivityTask = Task { [weak self] in
            guard let self else { return }
            // Each subscriber gets current + subsequent flips
            for await isUp in self.network.connectivityStream() {
                if isUp {
                    await self.warmRefreshParkedRequestsOnReconnect()
                }
            }
        }
    }
    
    deinit {
        connectivityTask?.cancel()
    }
    
    // MARK: - Public API
    
    public func artworksPage(
        artistID: Int,
        page: Int,
        pageSize: Int,
        policy: CachePolicy
    ) async throws -> Page<Artwork> {
        
        let artistKey = await ArtworkStore.artistKey(for: artistID)
        
        // 1) TTL fresh? Return cached and skip network.
        if let refreshedAt = try? await store.pageRefreshedAt(artistKey: artistKey, page: page),
           Date().timeIntervalSince(refreshedAt) < policy.pageTTL {
            let items = try await store.artworks(artistKey: artistKey, page: page)
            let meta = try await store.meta(artistKey: artistKey, page: page, fallbackPageSize: pageSize)
            return Page(items: items, page: page, pageSize: meta.pageSize, totalPages: .max, totalItems: meta.totalItems)
        }
        
        // 2) If online → try network, else park and fall back to cache.
        if network.isConnected {
            do {
                let fresh = try await api.fetchArtworksPage(artistID: artistID, page: page, pageSize: pageSize)
                try await store.upsert(pageResult: fresh, artistKey: artistKey)
                // Notify listeners
                await events.post(.pageUpdated(artistID: artistID, page: page))
                
                let items = try await store.artworks(artistKey: artistKey, page: page)
                return Page(items: items, page: fresh.page, pageSize: fresh.pageSize, totalPages: fresh.totalPages, totalItems: fresh.totalItems)
            } catch {
                // Park if fetch fails; still try to serve cache if available
                await queue.park(artistID: artistID, page: page, pageSize: pageSize)
                
                if let cached = try? await store.artworks(artistKey: artistKey, page: page), !cached.isEmpty {
                    let meta = try? await store.meta(artistKey: artistKey, page: page, fallbackPageSize: pageSize)
                    return Page(items: cached, page: page, pageSize: meta?.pageSize ?? pageSize, totalPages: .max, totalItems: meta?.totalItems ?? cached.count)
                }
                throw Self.mapError(error)
            }
        } else {
            // 3) Offline → always park the request for later
            await queue.park(artistID: artistID, page: page, pageSize: pageSize)
            
            // Serve cache if we have it; else throw domain error
            let cached = (try? await store.artworks(artistKey: artistKey, page: page)) ?? []
            if !cached.isEmpty {
                let meta = try? await store.meta(artistKey: artistKey, page: page, fallbackPageSize: pageSize)
                return Page(items: cached, page: page, pageSize: meta?.pageSize ?? pageSize, totalPages: .max, totalItems: meta?.totalItems ?? cached.count)
            } else {
                throw DomainError.offlineNoCache
            }
        }
    }
    
    public func warmRefreshParkedRequestsOnReconnect() async {
        guard network.isConnected else { return }
        let pending = await queue.snapshot()
        for req in pending {
            do {
                let fresh = try await api.fetchArtworksPage(artistID: req.artistID, page: req.page, pageSize: req.pageSize)
                try await store.upsert(pageResult: fresh, artistKey: ArtworkStore.artistKey(for: req.artistID))
                await queue.unpark(req)
                // Tell listeners that this page is now fresh in the store
                await events.post(.pageUpdated(artistID: req.artistID, page: req.page))
            } catch {
                // Keep parked; we'll retry on next reconnect
            }
        }
    }
    
    // MARK: - Error mapping
    
    private static func mapError(_ error: Error) -> DomainError {
        if (error as? URLError)?.code == .cancelled { return .cancelled }
        //  TODO: Handle this more gracefully
        if (error as? URLError)?.code.rawValue == -1011 { return .transportFailure(message: "You have reached the end") }
        if let urlErr = error as? URLError { return .transportFailure(message: urlErr.localizedDescription) }
        if error is DecodingError { return .invalidData }
        return .unknown(message: (error as NSError).localizedDescription)
    }
}
