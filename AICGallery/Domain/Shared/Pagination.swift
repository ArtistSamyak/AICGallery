//
//  Pagination.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

/// Generic page result wrapper for any paged content returned by a repository.
public struct Page<Item: Sendable & Hashable>: Sendable, Hashable {
    public let items: [Item]
    public let page: Int
    public let pageSize: Int
    public let totalPages: Int
    public let totalItems: Int
    
    public init(
        items: [Item],
        page: Int,
        pageSize: Int,
        totalPages: Int,
        totalItems: Int
    ) {
        self.items = items
        self.page = page
        self.pageSize = pageSize
        self.totalPages = totalPages
        self.totalItems = totalItems
    }
}
