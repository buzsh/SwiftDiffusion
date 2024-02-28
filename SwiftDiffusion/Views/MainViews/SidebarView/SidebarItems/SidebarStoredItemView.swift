//
//  SidebarStoredItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

/// Represents a view for displaying stored sidebar items, including handling for small and large previews.
/// This view dynamically selects and presents thumbnail or preview images based on user interaction toggles.
/// - Parameters:
///   - item: The `SidebarItem` to display, including all associated image and model information.
///   - smallPreviewsButtonToggled: A Boolean value indicating whether small previews are enabled.
///   - largePreviewsButtonToggled: A Boolean value indicating whether large previews are enabled.
///   - modelNameButtonToggled: A Boolean value indicating whether the model name display is enabled.
struct SidebarStoredItemView: View {
  let item: SidebarItem
  
  @State private var currentSmallThumbnailImageUrl: URL?
  @State private var currentLargeImageUrl: URL?
  
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      if sidebarViewModel.smallPreviewsButtonToggled, let thumbnailUrl = thumbnailInfo?.url {
        CachedThumbnailImageView(imageUrl: thumbnailUrl, width: 70, height: 70)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(color: .black, radius: 1, x: 0, y: 1)
      }
      
      VStack(alignment: .leading) {
        if sidebarViewModel.largePreviewsButtonToggled, let largePreviewInfo = previewInfo {
          CachedPreviewImageView(imageInfo: largePreviewInfo)
            .scaledToFill()
            .frame(width: sidebarViewModel.currentWidth)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black, radius: 1, x: 0, y: 1)
            .padding(.bottom, 8)
        }
        
        Text(item.title)
          .lineLimit(2)
        
        if sidebarViewModel.modelNameButtonToggled, let modelName = item.prompt?.selectedModel?.name {
          Text(modelName)
            .font(.system(size: 10, weight: .light, design: .monospaced))
            .foregroundStyle(Color.secondary)
            .padding(.top, 1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
  
  var thumbnailInfo: ImageInfo? {
    item.imageThumbnails.first(where: { $0.url.lastPathComponent.contains("-grid") })
    ?? item.imageThumbnails.last
  }
  
  var previewInfo: ImageInfo? {
    item.imagePreviews.first(where: { $0.url.lastPathComponent.contains("-grid") })
    ?? item.imagePreviews.last
  }
}
