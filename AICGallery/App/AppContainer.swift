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
        // SwiftData container with our models
        let schema = Schema([ArtworkRecord.self, PageRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        
        // Shared services
        network = NetworkMonitor()
        apiClient = ArtAPIClient()
        events = ArtworkEventBus()
        
        // Repository receives `events` so it can post .pageUpdated
        artworkRepository = ArtworkRepository(
            api: apiClient,
            modelContext: modelContext,
            network: network,
            events: events
        )
    }
}
