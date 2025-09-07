//
//  ParkedRequest.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

public struct ParkedRequest: Hashable, Sendable {
    let artistID: Int
    let page: Int
    let pageSize: Int
}

public actor ParkedRequestQueue {
    private var set = Set<ParkedRequest>()
    
    public init() {}
    
    public func park(artistID: Int, page: Int, pageSize: Int) {
        set.insert(.init(artistID: artistID, page: page, pageSize: pageSize))
    }
    
    public func snapshot() -> [ParkedRequest] { Array(set) }
    
    public func unpark(_ request: ParkedRequest) {
        set.remove(request)
    }
}
