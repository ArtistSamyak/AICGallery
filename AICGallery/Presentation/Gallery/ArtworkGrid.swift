//
//  ArtworkGrid.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import SwiftUI

public struct ArtworkGridItem<Content: View>: Identifiable {
    public let id: AnyHashable
    public let aspectRatio: CGFloat
    public let page: Int             // global index (used for pagination decisions)
    public let content: () -> Content
    
    public init(
        id: AnyHashable,
        aspectRatio: CGFloat,
        page: Int,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.aspectRatio = max(0.1, aspectRatio)
        self.page = page
        self.content = content
    }
}

public struct ArtworkGrid<Content: View>: View {
    private let items: [ArtworkGridItem<Content>]
    private let minColumnWidth: CGFloat
    private let spacing: CGFloat
    private let footerHeight: CGFloat = 84
    private let onPageChange: ((Int) -> Void)?
    
    @State private var currentPage = 0
    
    /// - Parameters:
    ///   - items: items with global index
    ///   - minColumnWidth: minimum column width; column count is derived from available width
    ///   - spacing: spacing between items and columns
    ///   - onPageChange: called when user is vewing a different page
    public init(
        items: [ArtworkGridItem<Content>],
        minColumnWidth: CGFloat = 160,
        spacing: CGFloat = 8,
        onPageChange: ((Int) -> Void)? = nil,
    ) {
        self.items = items
        self.minColumnWidth = minColumnWidth
        self.spacing = spacing
        self.onPageChange = onPageChange
    }
    
    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let columns = max(1, Int((width + spacing) / (minColumnWidth + spacing)))
            let columnWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            
            // Distribute lazily by predicted heights (no actual layout needed)
            let distributed = distribute(items: items, columns: columns, columnWidth: columnWidth)
            
            ScrollView {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        LazyVStack(spacing: spacing) {
                            ForEach(distributed[col]) { item in
                                let imageHeight = max(1, item.aspectRatio * columnWidth)
                                let totalHeight = imageHeight + footerHeight
                                
                                item.content()
                                    .frame(width: columnWidth, height: totalHeight)
                                    .onAppear {
                                        if item.page != currentPage {
                                            currentPage = item.page
                                            onPageChange?(item.page)
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 0)
                .padding(.top, 0)
            }
        }
    }
    
    // MARK: - Distribution by running column heights
    private func distribute(
        items: [ArtworkGridItem<Content>],
        columns: Int,
        columnWidth: CGFloat
    ) -> [[ArtworkGridItem<Content>]] {
        guard columns > 1 else { return [items] }
        var result: [[ArtworkGridItem<Content>]] = Array(repeating: [], count: columns)
        var heights: [CGFloat] = Array(repeating: 0, count: columns)
        
        for item in items {
            let predicted = max(1, item.aspectRatio * columnWidth) + footerHeight
            // choose shortest column
            let col = heights.enumerated().min(by: { $0.element < $1.element })!.offset
            result[col].append(item)
            heights[col] += (result[col].isEmpty ? 0 : spacing) + predicted
        }
        return result
    }
}

