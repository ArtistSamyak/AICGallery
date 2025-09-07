//
//  ArtworkEvent.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//


import Foundation

public enum ArtworkEvent: Sendable, Equatable {
    case pageUpdated(artistID: Int, page: Int)
}

public protocol ArtworkEventBusProtocol: Sendable {
    /// Subscribe to artwork events. Each call returns a fresh stream.
    func stream() -> AsyncStream<ArtworkEvent>
}
