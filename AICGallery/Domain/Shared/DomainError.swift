//
//  DomainError.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Errors surfaced at the domain boundary. Concrete data-layer errors are mapped into these.
public enum DomainError: Error, Equatable, Sendable {
    /// No network available and no cached data to satisfy the request.
    case offlineNoCache
    /// Request failed due to network/server issues (status codes, timeouts, etc.).
    case transportFailure(message: String?)
    /// Data was received but could not be parsed or validated.
    case invalidData
    /// Requested resource not found.
    case notFound
    /// Operation cancelled (e.g., user left screen).
    case cancelled
    /// Generic catch-all.
    case unknown(message: String?)
    
    public static func == (lhs: DomainError, rhs: DomainError) -> Bool {
        switch (lhs, rhs) {
        case (.offlineNoCache, .offlineNoCache): return true
        case (.invalidData, .invalidData): return true
        case (.notFound, .notFound): return true
        case (.cancelled, .cancelled): return true
        case let (.transportFailure(a), .transportFailure(b)): return a == b
        case let (.unknown(a), .unknown(b)): return a == b
        default: return false
        }
    }
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .offlineNoCache:
            return "You’re offline and no cache is available."
        case .transportFailure(let msg):
            return msg ?? "Network error. Please try again."
        case .invalidData:
            return "Couldn’t read data from server."
        case .notFound:
            return "Not found."
        case .cancelled:
            return "Cancelled."
        case .unknown:
            return "Something went wrong."
        }
    }
}
