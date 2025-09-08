//
//  ArtAPIClient.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

protocol ArtAPIClientProtocol: Sendable {
    func fetchArtworksPage(
        artistID: Int,
        page: Int,
        pageSize: Int
    ) async throws -> ArtPageResult
    
    func iiifThumbnailURL(imageID: String, width: Int) -> URL
    func iiifDetailURL(imageID: String, width: Int) -> URL
}

/// Minimal, testable API client for the Art Institute of Chicago search API.
/// Uses async/await and decodes only the fields we require.
final class ArtAPIClient: ArtAPIClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.artic.edu/api/v1")!
    
    // IIIF base may be returned per response via `config.iiif_url`.
    // We keep the last-seen value around as a fallback for subsequent constructions.
    private var lastKnownIIIFBase: String = "https://www.artic.edu/iiif/2"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchArtworksPage(
        artistID: Int,
        page: Int,
        pageSize: Int
    ) async throws -> ArtPageResult {
        var comps = URLComponents(url: baseURL.appendingPathComponent("artworks/search"), resolvingAgainstBaseURL: false)!
        // Build query: search by artist_id, include fields we need, set pagination.
        let fields = [
            "id", "title", "thumbnail", "image_id", "artist_title", "api_model", "api_link"
        ].joined(separator: ",")
        
        comps.queryItems = [
            .init(name: "query[term][artist_id]", value: String(artistID)),
            .init(name: "fields", value: fields),
            .init(name: "page", value: String(page)),
            .init(name: "limit", value: String(pageSize))
        ]
        
        let (data, response) = try await session.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let decoded = try decoder.decode(ArtSearchResponse.self, from: data)
        
        // Remember iiif base for later URL construction
        self.lastKnownIIIFBase = decoded.config.iiifURL
        
        return ArtPageResult(
            items: decoded.data,
            page: decoded.pagination.currentPage,
            pageSize: decoded.pagination.limit,
            totalPages: decoded.pagination.totalPages,
            totalItems: decoded.pagination.total
            ,   iiifBase: decoded.config.iiifURL
        )
    }
    
    // We will use these when we implement custom image caching
    func iiifThumbnailURL(imageID: String, width: Int) -> URL {
        // IIIF pattern: /{id}/full/{width},/0/default.jpg
        URL(string: "\(lastKnownIIIFBase)/\(imageID)/full/\(width),/0/default.jpg")!
    }
    
    func iiifDetailURL(imageID: String, width: Int) -> URL {
        URL(string: "\(lastKnownIIIFBase)/\(imageID)/full/\(width),/0/default.jpg")!
    }
}
