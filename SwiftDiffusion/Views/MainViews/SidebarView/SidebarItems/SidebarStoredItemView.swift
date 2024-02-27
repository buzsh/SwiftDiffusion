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
  
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      if smallPreviewsButtonToggled {
        if let thumbnailUrl = smallPreviewURL {
          CachedPreviewImageView(imageUrl: thumbnailUrl)
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 65)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black, radius: 1, x: 0, y: 1)
        }
      }
      
      VStack(alignment: .leading) {
        if largePreviewsButtonToggled, let largePreviewUrl = largePreviewURL {
          CachedPreviewImageView(imageUrl: largePreviewUrl)
            .scaledToFill()
            .frame(width: sidebarViewModel.currentWidth)
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black, radius: 1, x: 0, y: 1)
            .padding(.bottom, 8)
        }
        
        Text(item.title)
          .lineLimit(2)
        
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
  
  var smallPreviewURL: URL? {
    item.imageThumbnails.first(where: { $0.url.lastPathComponent.contains("-grid") })?.url
    ?? item.imageThumbnails.last?.url
    ?? item.imageUrls.last
  }
  
  var largePreviewURL: URL? {
    item.imagePreviews.first(where: { $0.url.lastPathComponent.contains("-grid") })?.url
    ?? item.imagePreviews.last?.url
    ?? item.imageUrls.last
  }
  
  var largePreviewAspectRatio: CGFloat {
    guard let largePreviewInfo = item.imagePreviews.first(where: { $0.url.lastPathComponent.contains("-grid") })
    else { return 1 } // Default aspect ratio
    return largePreviewInfo.height / max(largePreviewInfo.width, 1) // Avoid division by zero
  }
}
