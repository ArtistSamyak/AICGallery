//
//  ArtworkStore.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation
import SwiftData

@MainActor
final class ArtworkStore {
    private let context: ModelContext
    
    init(modelContext: ModelContext) { self.context = modelContext }
    
    // MARK: - Keys
    
    static func artistKey(for artistID: Int) -> String { "artistID:\(artistID)" }
    
    private func deriveArtistID(from artistKey: String) -> Int {
        Int(artistKey.split(separator: ":").last ?? "") ?? 0
    }
    
    // MARK: - Reads
    
    func pageRefreshedAt(artistKey: String, page: Int) throws -> Date {
        let fetchDescriptor = FetchDescriptor<PageRecord>(
            predicate: #Predicate { $0.artistKey == artistKey && $0.page == page }
        )
        if let record = try context.fetch(fetchDescriptor).first { return record.refreshedAt }
        return .distantPast
    }
    
    func artworks(artistKey: String, page: Int) throws -> [Artwork] {
        let fetchDescriptor = FetchDescriptor<ArtworkRecord>(
            predicate: #Predicate { $0.artistKey == artistKey && $0.page == page },
            sortBy: [SortDescriptor(\.id)]
        )
        let records = try context.fetch(fetchDescriptor)
        return records.map {
            Artwork(
                id: $0.id,
                title: $0.title,
                artistID: $0.artistID,
                imageID: $0.imageID,
                thumbnailWidth: $0.thumbWidth,
                thumbnailHeight: $0.thumbHeight,
                thumbnailAltText: $0.thumbAlt
            )
        }
    }
    
    struct PageMeta { let pageSize: Int; let totalPages: Int; let totalItems: Int }
    
    func meta(artistKey: String, page: Int, fallbackPageSize: Int) throws -> PageMeta {
        let count = try context.fetchCount(
            FetchDescriptor<ArtworkRecord>(predicate: #Predicate { $0.artistKey == artistKey && $0.page == page })
        )
        return .init(pageSize: count > 0 ? count : fallbackPageSize, totalPages: 1, totalItems: count)
    }
    
    // MARK: - Writes
    
    func upsert(pageResult: ArtPageResult, artistKey: String) throws {
        let artistID = deriveArtistID(from: artistKey)
        let prPage = pageResult.page
        
        for item in pageResult.items {
            guard let imageID = item.imageId else { continue }
            let thumbW = item.thumbnail?.width ?? 1
            let thumbH = item.thumbnail?.height ?? 1
            
            // capture ID as a plain value for the predicate
            let targetID = item.id
            
            // fetch existing by unique id
            let fetchDescriptor = FetchDescriptor<ArtworkRecord>(
                predicate: #Predicate { $0.id == targetID }
            )
            if let existing = try context.fetch(fetchDescriptor).first {
                existing.title = item.title
                existing.artistID = artistID
                existing.imageID = imageID
                existing.thumbWidth = thumbW
                existing.thumbHeight = thumbH
                existing.thumbAlt = item.thumbnail?.altText
                existing.page = prPage
                existing.artistKey = artistKey
            } else {
                context.insert(
                    ArtworkRecord(
                        id: targetID,
                        title: item.title,
                        artistID: artistID,
                        imageID: imageID,
                        thumbWidth: thumbW,
                        thumbHeight: thumbH,
                        thumbAlt: item.thumbnail?.altText,
                        page: prPage,
                        artistKey: artistKey
                    )
                )
            }
        }
        
        // Upsert page TTL record (capture locals)
        let pageFetchDescriptor = FetchDescriptor<PageRecord>(
            predicate: #Predicate { $0.artistKey == artistKey && $0.page == prPage }
        )
        if let pageRecord = try context.fetch(pageFetchDescriptor).first {
            pageRecord.refreshedAt = Date()
        } else {
            context.insert(PageRecord(artistKey: artistKey, page: prPage, refreshedAt: Date()))
        }
        
        try context.save()
    }
}
