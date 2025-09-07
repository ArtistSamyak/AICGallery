//
//  GetArtworksPage.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Use case for retrieving a page of artworks with domain-level intent.
/// Keeps the Presentation layer ignorant of repository details and cache semantics.
public protocol GetArtworksPageUseCaseProtocol: Sendable {
    func execute(
        artistID: Int,
        page: Int,
        pageSize: Int
    ) async throws -> Page<Artwork>
}

public final class GetArtworksPageUseCase: GetArtworksPageUseCaseProtocol, @unchecked Sendable {
    private let repository: ArtworkRepositoryProtocol
    private let cachePolicy: CachePolicy
    
    public init(
        repository: ArtworkRepositoryProtocol,
        cachePolicy: CachePolicy = .init(pageTTL: 300)
    ) {
        self.repository = repository
        self.cachePolicy = cachePolicy
    }
    
    public func execute(
        artistID: Int,
        page: Int,
        pageSize: Int
    ) async throws -> Page<Artwork> {
        try await repository.artworksPage(
            artistID: artistID,
            page: page,
            pageSize: pageSize,
            policy: cachePolicy
        )
    }
}
