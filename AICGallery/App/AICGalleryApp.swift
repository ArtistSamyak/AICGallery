//
//  AICGalleryApp.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import SwiftUI
import SwiftData

@main
struct AICGalleryApp: App {
    private let container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            let repo = container.artworkRepository
            let cachePolicy = CachePolicy(pageTTL: 300)     // 5 minutes
            let getPage = GetArtworksPageUseCase(repository: repo, cachePolicy: cachePolicy)
            let refreshParked = RefreshParkedRequestsUseCase(repository: repo)
            
            let vm = GalleryViewModel(
                artistID: 34946,    // Utagawa Hiroshige
                pageSize: 20,       // number of items in each page
                getPage: getPage,
                refreshParked: refreshParked,
                network: container.network,
                events: container.events
            )
            
            GalleryView(vm)
                .modelContainer(container.modelContainer) // SwiftData context in env
        }
    }
}
