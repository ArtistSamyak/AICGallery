//
//  RefreshParkedRequestsOnReconnect..swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Use case to be triggered by connectivity changes; lets the repo drain its parked queue.
public protocol RefreshParkedRequestsUseCaseProtocol: Sendable {
    func execute() async
}

public final class RefreshParkedRequestsUseCase: RefreshParkedRequestsUseCaseProtocol, @unchecked Sendable {
    private let repository: ArtworkRepositoryProtocol
    
    public init(repository: ArtworkRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async {
        await repository.warmRefreshParkedRequestsOnReconnect()
    }
}
