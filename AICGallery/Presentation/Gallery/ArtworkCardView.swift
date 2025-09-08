//
//  ArtworkCardView.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import SwiftUI

struct ArtworkCardView: View {
    let artwork: Artwork
    let thumbnailWidth: Int = 400
    
    private let footerHeight: CGFloat = 84
    
    private var thumbURL: URL? {
        artwork.iiifImageURL(imageID: artwork.imageID, width: thumbnailWidth)
    }
    
    var body: some View {
        GeometryReader { geo in
            let imageHeight = max(0, geo.size.height - footerHeight)
            
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.12))
                            ProgressView().tint(.secondary)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity)
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.12))
                            Image(systemName: "exclamationmark.triangle.fill")
                                .imageScale(.large).foregroundStyle(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: imageHeight)
                
                // Title block occupies the reserved footerHeight
                Text(artwork.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(height: footerHeight, alignment: .topLeading)
                    .foregroundStyle(.primary)
                    .accessibilityLabel(artwork.title)
            }
        }
    }
}
