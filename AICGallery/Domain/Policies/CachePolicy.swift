//
//  CachePolicy.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Abstraction describing when a cached page is considered fresh.
/// Kept in Domain so it's easily configurable & testable.
public struct CachePolicy: Sendable, Hashable {
    public let pageTTL: TimeInterval  // seconds
    
    public init(pageTTL: TimeInterval = 300) { // default: 5 minutes
        self.pageTTL = pageTTL
    }
}
