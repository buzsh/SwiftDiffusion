//
//  SidebarStoredItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

struct SidebarStoredItemView: View {
  let item: SidebarItem
  let smallPreviewsButtonToggled: Bool
  let largePreviewsButtonToggled: Bool
  let modelNameButtonToggled: Bool
  
  @State private var currentSmallThumbnailImageUrl: URL?
  @State private var currentLargeImageUrl: URL?
  
  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      if smallPreviewsButtonToggled {
        CachedPreviewImageView(fallbackUrl: item.imageUrls.last!, imageUrl: $currentSmallThumbnailImageUrl)
          .frame(width: 50, height: 65)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(color: .black, radius: 1, x: 0, y: 1)
        
      }
      
      VStack(alignment: .leading) {
        if largePreviewsButtonToggled {
          CachedPreviewImageView(fallbackUrl: item.imagePreviewUrls?.last ?? item.imageUrls.last!, imageUrl: $currentLargeImageUrl)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black, radius: 1, x: 0, y: 1)
            .padding(.bottom, 8)
        }
        
        Text(item.title)
          .lineLimit(modelNameButtonToggled ? 1 : 2)
        
        if modelNameButtonToggled, let modelName = item.prompt?.selectedModel?.name {
          Text(modelName)
            .font(.system(size: 10, weight: .light, design: .monospaced))
            .foregroundStyle(Color.secondary)
            .padding(.top, 1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
