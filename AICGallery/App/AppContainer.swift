//
//  AppContainer.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation
import SwiftData

@MainActor
struct AppContainer {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let network: NetworkMonitor
    let apiClient: ArtAPIClient
    let events: ArtworkEventBus
    let artworkRepository: ArtworkRepository
    
    init() {
        // SwiftData container
        let schema = Schema([ArtworkRecord.self, PageRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        
        // Bump URLCache for images (AsyncImage uses URLSession.shared)
        let memoryCap = 100 * 1024 * 1024   // 100 MB RAM
        let diskCap   = 500 * 1024 * 1024   // 500 MB disk
        URLCache.shared = URLCache(memoryCapacity: memoryCap,
                                   diskCapacity: diskCap,
                                   directory: nil)
        
        // Non-caching session for API JSON (keeps domain TTL in charge)
        let cfg = URLSessionConfiguration.default
        cfg.urlCache = nil
        cfg.requestCachePolicy = .reloadRevalidatingCacheData // conditional GETs ok
        cfg.waitsForConnectivity = false // we handle parking explicitly
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 40
        let apiSession = URLSession(configuration: cfg)
        
        // 4) Shared services
        network = NetworkMonitor()
        apiClient = ArtAPIClient(session: apiSession)
        events = ArtworkEventBus()
        
        // 5) Repository (posts .pageUpdated, drains parked on reconnect)
        artworkRepository = ArtworkRepository(
            api: apiClient,
            modelContext: modelContext,
            network: network,
            events: events
        )
    }
}
