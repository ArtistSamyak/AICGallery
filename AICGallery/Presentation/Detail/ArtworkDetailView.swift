//
//  ArtworkDetailView.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import SwiftUI

struct ArtworkDetailView: View {
    let artwork: Artwork
    
    // IIIF detail width ~843 recommended
    private var detailURL: URL? {
        URL(string: "https://www.artic.edu/iiif/2/\(artwork.imageID)/full/843,/0/default.jpg")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: detailURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack { Rectangle().fill(.secondary.opacity(0.12)); ProgressView() }
                            .frame(height: 300)
                    case .success(let img):
                        img.resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .transition(.opacity)
                            .accessibilityLabel(artwork.thumbnailAltText ?? artwork.title)
                    case .failure:
                        ZStack { Rectangle().fill(.secondary.opacity(0.12))
                            Image(systemName: "exclamationmark.triangle").imageScale(.large)
                        }.frame(height: 300)
                    @unknown default: EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(artwork.title)
                        .font(.title2).fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .accessibilityAddTraits(.isHeader)
                    Text("Artist ID: \(artwork.artistID)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // More metadata could be added if needed.
                }
            }
            .padding(16)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}
