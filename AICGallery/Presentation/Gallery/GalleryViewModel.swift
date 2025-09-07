//
//  GalleryViewModel.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

@MainActor
final class GalleryViewModel: ObservableObject {
    // Inputs
    private let artistID: Int
    private let pageSize: Int
    private let getPage: GetArtworksPageUseCaseProtocol
    private let refreshParked: RefreshParkedRequestsUseCaseProtocol
    private let network: NetworkMonitorProtocol
    private let events: ArtworkEventBusProtocol

    // UI State
    @Published private(set) var pages: [Int: [Artwork]] = [:]
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var isOffline: Bool = false

    // Debounce & concurrency guards
    private var pageChangeDebounceTask: Task<Void, Never>?
    private var lastEmittedPage: Int?
    private var loadingPages = Set<Int>()

    private var connectivityTask: Task<Void, Never>?
    private var eventsTask: Task<Void, Never>?
    
    init(
        artistID: Int,
        pageSize: Int = 20,
        getPage: GetArtworksPageUseCaseProtocol,
        refreshParked: RefreshParkedRequestsUseCaseProtocol,
        network: NetworkMonitorProtocol,
        events: ArtworkEventBusProtocol
    ) {
        self.artistID = artistID
        self.pageSize = pageSize
        self.getPage = getPage
        self.refreshParked = refreshParked
        self.network = network
        self.events = events

        // Connectivity
        connectivityTask = Task { [weak self] in
            guard let self else { return }
            for await connected in network.connectivityStream() {
                self.isOffline = !connected
                if connected {
                    await self.refreshParked.execute()
                    if self.pages.isEmpty { await self.load(page: 1) }
                }
            }
        }

        // Events
        eventsTask = Task { [weak self] in
            guard let self else { return }
            for await event in events.stream() {
                if case let .pageUpdated(aID, page) = event, aID == self.artistID {
                    await self.reloadPage(page)
                }
            }
        }
    }
    
    deinit {
        connectivityTask?.cancel()
        eventsTask?.cancel()
        pageChangeDebounceTask?.cancel()
    }

    func initialLoad() {
        if pages.isEmpty {
            Task { await load(page: 1) }
        }
    }

    // Called by the view when the visible section changes (DEBOUNCED).
    func onPageChange(to page: Int) {
        pageChangeDebounceTask?.cancel()
        pageChangeDebounceTask = Task { [weak self] in
            // 250ms debounce feels snappy; adjust 200-350ms as taste.
            try? await Task.sleep(nanoseconds: 250_000_000)
            await self?.handleDebouncedPageChange(page)
        }
    }

    private func handleDebouncedPageChange(_ page: Int) async {
        // Ignore repeats of the same page
        if lastEmittedPage == page { return }
        lastEmittedPage = page

        await load(page: page)           // ensure current page exists/refreshes via TTL
        if pages[page + 1] == nil {      // prefetch next page if missing
            await load(page: page + 1)
        }
    }

    func clearError() {
        Task { @MainActor [weak self] in
            self?.errorMessage = nil
        }
    }

    // MARK: - Internals

    private func load(page: Int) async {
        // Prevent duplicate in-flight loads of the same page
        if loadingPages.contains(page) { return }
        loadingPages.insert(page)
        defer { loadingPages.remove(page) }

        do {
            let result = try await getPage.execute(artistID: artistID, page: page, pageSize: pageSize)
            pages[page] = result.items
            errorMessage = nil
        } catch {
            if case DomainError.offlineNoCache = error { isOffline = true }
            errorMessage = (error as? DomainError)?.localizedDescription
                ?? (error as NSError).localizedDescription
        }
    }

    private func reloadPage(_ page: Int) async {
        // Use same guard to avoid collisions with an ongoing load(page:)
        if loadingPages.contains(page) { return }
        loadingPages.insert(page)
        defer { loadingPages.remove(page) }

        do {
            let result = try await getPage.execute(artistID: artistID, page: page, pageSize: pageSize)
            pages[page] = result.items
        } catch {
            // Soft-fail: keep displaying the previous data
        }
    }
}
