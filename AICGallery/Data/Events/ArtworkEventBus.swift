//
//  ArtworkEventBus.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation

public actor ArtworkEventBus: @preconcurrency ArtworkEventBusProtocol {
    private var continuations: [UUID: AsyncStream<ArtworkEvent>.Continuation] = [:]
    
    deinit {
        for value in continuations.values { value.finish() }
        continuations.removeAll()
    }
    
    public func stream() -> AsyncStream<ArtworkEvent> {
        let id = UUID()
        return AsyncStream<ArtworkEvent>(bufferingPolicy: .bufferingNewest(10)) { cont in
            continuations[id] = cont
            cont.onTermination = { [weak self] _ in
                Task { await self?.remove(id: id) }
            }
        }
    }
    
    public func post(_ event: ArtworkEvent) {
        for value in continuations.values { value.yield(event) }
    }
    
    private func remove(id: UUID) {
        continuations[id]?.finish()
        continuations[id] = nil
    }
}
