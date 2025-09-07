//
//  GalleryView.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel: GalleryViewModel
    
    init(_ viewModel: GalleryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var totalItems: Int {
        viewModel.pages.values.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ArtworkGrid(
                    items: {
                        let orderedPages = viewModel.pages.keys.sorted()
                        let pairs: [(page: Int, art: Artwork)] =
                        orderedPages.flatMap { p in (viewModel.pages[p] ?? []).map { (p, $0) } }
                        
                        return pairs.map { pair in
                            ArtworkGridItem(
                                id: AnyHashable("\(pair.page)-\(pair.art.id)"),
                                aspectRatio: max(pair.art.thumbnailAspectRatio, 0.25),
                                page: pair.page
                            ) {
                                NavigationLink {
                                    ArtworkDetailView(artwork: pair.art)
                                } label: {
                                    ArtworkCardView(artwork: pair.art)
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .contain)
                            }
                        }
                    }(),
                    minColumnWidth: 160,
                    spacing: 10,
                    onPageChange: { page in
                        viewModel.onPageChange(to: page)
                    }
                )
                .padding(.horizontal, 12)
                .padding(.top, viewModel.isOffline ? 44 : 0)
                .navigationTitle("Artworks")
                .navigationBarTitleDisplayMode(.inline)
                .task { viewModel.initialLoad() }
                
                if viewModel.isOffline {
                    ToastBanner(text: "Offline — showing cached data")
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isOffline)
        .animation(.easeInOut(duration: 0.2), value: totalItems)
        .alert(
            "",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            ),
            actions: {
                Button("OK", role: .cancel) { viewModel.clearError() }
            },
            message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        )
    }
}
