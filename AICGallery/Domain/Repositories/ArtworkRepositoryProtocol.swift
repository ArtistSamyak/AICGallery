//
//  ArtworkRepositoryProtocol.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Abstraction for fetching and caching paged artworks for a specific artist.
public protocol ArtworkRepositoryProtocol: Sendable {
    /// Fetches a specific page of artworks for an artist.
    ///
    /// Implementations must:
    /// - Respect per-page TTL (`policy.pageTTL`) and return cached page if fresh.
    /// - If stale and online, refresh the page from network, update cache, return fresh items.
    /// - If offline:
    ///     - Return cached page if available and park a background refresh for later.
    ///     - If no cache, throw `.offlineNoCache`.
    ///
    /// - Parameters:
    ///   - artistID: Art Institute artist identifier.
    ///   - page: 1-based page index.
    ///   - pageSize: number of items per page (API limit).
    ///   - policy: per-page cache policy.
    func artworksPage(
        artistID: Int,
        page: Int,
        pageSize: Int,
        policy: CachePolicy
    ) async throws -> Page<Artwork>
    
    /// Hint to an implementation to retry any parked fetches (e.g., after connectivity resumes).
    func warmRefreshParkedRequestsOnReconnect() async
}
