//
//  Artwork.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Domain entity representing an artwork as used by the app.
/// Pure value type; no framework dependencies.
public struct Artwork: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let artistID: Int
    public let imageID: String
    
    /// Thumbnail metadata to support responsive waterfall layout.
    /// The API provides thumbnail width/height; we forward them to UI.
    public let thumbnailWidth: Int
    public let thumbnailHeight: Int
    public let thumbnailAltText: String?
    
    /// Convenience computed aspect ratio (height / width).
    public var thumbnailAspectRatio: CGFloat {
        guard thumbnailWidth > 0 else { return 1.0 }
        return CGFloat(thumbnailHeight) / CGFloat(thumbnailWidth)
    }
    
    public init(
        id: Int,
        title: String,
        artistID: Int,
        imageID: String,
        thumbnailWidth: Int,
        thumbnailHeight: Int,
        thumbnailAltText: String?
    ) {
        self.id = id
        self.title = title
        self.artistID = artistID
        self.imageID = imageID
        self.thumbnailWidth = thumbnailWidth
        self.thumbnailHeight = thumbnailHeight
        self.thumbnailAltText = thumbnailAltText
    }
}

extension Artwork {
    func iiifImageURL(imageID: String, width: Int) -> URL? {
        URL(string: "https://www.artic.edu/iiif/2/\(imageID)/full/\(width),/0/default.jpg")
    }
}
