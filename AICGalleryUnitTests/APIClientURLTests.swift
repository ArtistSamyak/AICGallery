//
//  APIClientURLTests.swift
//  AICGallery
//
//  Created by Samyak Pawar on 07/09/2025.
//

import Foundation
import Testing
@testable import AICGallery

@Suite("ArtAPIClient URL builders")
struct APIClientURLTests {

    @Test
    func iiifBuilders() {
        let client = ArtAPIClient()
        let thumb = client.iiifThumbnailURL(imageID: "abcd", width: 400).absoluteString
        let detail = client.iiifDetailURL(imageID: "abcd", width: 843).absoluteString

        #expect(thumb.contains("/abcd/full/400,/0/default.jpg"))
        #expect(detail.contains("/abcd/full/843,/0/default.jpg"))
    }
}
