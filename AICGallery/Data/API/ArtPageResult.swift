//
//  ArtPageResult.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import Foundation

struct ArtSearchResponse: Decodable, Sendable {
    struct Pagination: Decodable, Sendable {
        let total: Int
        let limit: Int
        let offset: Int
        let totalPages: Int
        let currentPage: Int
        
        enum CodingKeys: String, CodingKey {
            case total, limit, offset
            case totalPages = "total_pages"
            case currentPage = "current_page"
        }
    }
    
    struct Item: Decodable, Sendable {
        let id: Int
        let title: String
        let thumbnail: Thumb?
        let imageId: String?
        let apiModel: String?
        let apiLink: String?
        let artistTitle: String?
        
        struct Thumb: Decodable, Sendable {
            let lqip: String?
            let width: Int?
            let height: Int?
            let altText: String?
            
            enum CodingKeys: String, CodingKey {
                case lqip, width, height
                case altText = "alt_text"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id, title, thumbnail
            case imageId = "image_id"
            case apiModel = "api_model"
            case apiLink = "api_link"
            case artistTitle = "artist_title"
        }
    }
    
    struct Config: Decodable, Sendable {
        let iiifURL: String
        let websiteURL: String?
        
        enum CodingKeys: String, CodingKey {
            case iiifURL = "iiif_url"
            case websiteURL = "website_url"
        }
    }
    
    let pagination: Pagination
    let data: [Item]
    let config: Config
    
    enum CodingKeys: String, CodingKey {
        case pagination, data, config
    }
}

struct ArtPageResult: Sendable {
    let items: [ArtSearchResponse.Item]
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalItems: Int
    let iiifBase: String
}
