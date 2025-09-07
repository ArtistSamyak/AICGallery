//
//  GalleryViewModel.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import Testing
@testable import AICGallery


private final class ThrowingRepo: ArtworkRepositoryProtocol, @unchecked Sendable {
    func artworksPage(artistID: Int, page: Int, pageSize: Int, policy: CachePolicy) async throws -> Page<Artwork> {
        throw DomainError.offlineNoCache
    }
    func warmRefreshParkedRequestsOnReconnect() async {}
}

@Suite("GalleryViewModel")
struct ViewModelTests {

    @MainActor
    @Test("onPageChange is debounced and prefetches next")
    func debouncedOnPageChange() async throws {
        // Fake repo through use case
        let repo = FakeRepository()
        let policy = CachePolicy(pageTTL: 300)
        let useCase = GetArtworksPageUseCase(repository: repo, cachePolicy: policy)

        // Seed page 3 & 4
        let p3 = Fixtures.domainPage(from: Fixtures.artPageResult(page: 3, count: 2))
        let p4 = Fixtures.domainPage(from: Fixtures.artPageResult(page: 4, count: 2))
        repo.pages[3] = p3
        repo.pages[4] = p4

        // No-op refresh parked
        struct RP: RefreshParkedRequestsUseCaseProtocol { func execute() async {} }

        // Network: start online
        let net = MockNetworkMonitor(initial: true)
        let bus = TestEventBus()

        let vm = GalleryViewModel(
            artistID: 34946,
            pageSize: 20,
            getPage: useCase,
            refreshParked: RP(),
            network: net,
            events: bus
        )

        // Rapid thrash between pages
        vm.onPageChange(to: 2)
        vm.onPageChange(to: 3)
        vm.onPageChange(to: 4)
        vm.onPageChange(to: 3) // final state wants page 3 visible

        // Wait for debounce
        try await TestWait.debounce()

        // Expect loads for 3 and 4 (prefetch of next)
        #expect(repo.calls.contains(where: { $0.page == 3 }))
        #expect(repo.calls.contains(where: { $0.page == 4 }))

        // Pages should be populated
        #expect(vm.pages[3]?.count == 2)
        #expect(vm.pages[4]?.count == 2)
    }

    @MainActor
    @Test("Connectivity → initial load when pages empty")
    func connectivityInitialLoad() async throws {
        let repo = FakeRepository()
        let p1 = Fixtures.domainPage(from: Fixtures.artPageResult(page: 1, count: 1))
        repo.pages[1] = p1

        let useCase = GetArtworksPageUseCase(repository: repo, cachePolicy: .init(pageTTL: 300))
        struct RP: RefreshParkedRequestsUseCaseProtocol { func execute() async {} }

        let net = MockNetworkMonitor(initial: true)
        let bus = TestEventBus()

        let vm = GalleryViewModel(
            artistID: 34946,
            pageSize: 20,
            getPage: useCase,
            refreshParked: RP(),
            network: net,
            events: bus
        )

        // VM's connectivity task should trigger load(page:1) since pages empty
        try await TestWait.medium()

        #expect(vm.pages[1]?.count == 1)
    }

    @MainActor
    @Test("Event .pageUpdated triggers targeted reload")
    func eventReloadsPage() async throws {
        let repo = FakeRepository()
        let useCase = GetArtworksPageUseCase(repository: repo, cachePolicy: CachePolicy(pageTTL: 300))
        struct RP: RefreshParkedRequestsUseCaseProtocol { func execute() async {} }

        let net = MockNetworkMonitor(initial: true)
        let bus = TestEventBus()

        let vm = GalleryViewModel(
            artistID: 34946,
            pageSize: 20,
            getPage: useCase,
            refreshParked: RP(),
            network: net,
            events: bus
        )

        // Let the VM start its `Task { for await event in events.stream() { ... } }`
        try await TestWait.short()

        // Seed repo page 2; when VM reloads, it will pull this
        repo.pages[2] = Fixtures.domainPage(from: Fixtures.artPageResult(page: 2, count: 5))

        // Now post the event
        await bus.post(.pageUpdated(artistID: 34946, page: 2))

        try await TestWait.short()

        #expect(vm.pages[2]?.count == 5)
    }
    
    @MainActor
    @Test("offlineNoCache sets banner + error, and clearError clears it")
    func errorFlow() async throws {
        let repo = ThrowingRepo()
        let useCase = GetArtworksPageUseCase(repository: repo, cachePolicy: CachePolicy(pageTTL: 300))

        struct RP: RefreshParkedRequestsUseCaseProtocol { func execute() async {} }
        let net = MockNetworkMonitor(initial: false)
        let bus = ArtworkEventBus()

        let vm = GalleryViewModel(
            artistID: 34946,
            pageSize: 20,
            getPage: useCase,
            refreshParked: RP(),
            network: net,
            events: bus
        )

        vm.initialLoad()
        try await TestWait.short()

        #expect(vm.isOffline == true)
        #expect(vm.errorMessage != nil)

        vm.clearError()
        try await TestWait.short()
        #expect(vm.errorMessage == nil)
    }
}
