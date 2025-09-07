//
//  ToastBanner.swift
//  AICGallery
//
//  Created by Samyak Pawar on 06/09/2025.
//

import SwiftUI

struct ToastBanner: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.footnote).bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.primary.opacity(0.15))
            )
    }
}
