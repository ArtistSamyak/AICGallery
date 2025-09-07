//
//  Models.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation
import SwiftData

@Model
final class ArtworkRecord {
    @Attribute(.unique) var id: Int
    var title: String
    var artistID: Int
    var imageID: String
    
    // For UI aspect ratio
    var thumbWidth: Int
    var thumbHeight: Int
    var thumbAlt: String?
    
    // Partitioning & pagination
    var page: Int
    var artistKey: String // "artistID:\(id)"
    
    init(
        id: Int,
        title: String,
        artistID: Int,
        imageID: String,
        thumbWidth: Int,
        thumbHeight: Int,
        thumbAlt: String?,
        page: Int,
        artistKey: String
    ) {
        self.id = id
        self.title = title
        self.artistID = artistID
        self.imageID = imageID
        self.thumbWidth = thumbWidth
        self.thumbHeight = thumbHeight
        self.thumbAlt = thumbAlt
        self.page = page
        self.artistKey = artistKey
    }
}

@Model
final class PageRecord {
    // Composite key via (artistKey,page)
    var artistKey: String
    var page: Int
    var refreshedAt: Date
    
    init(artistKey: String, page: Int, refreshedAt: Date) {
        self.artistKey = artistKey
        self.page = page
        self.refreshedAt = refreshedAt
    }
}
