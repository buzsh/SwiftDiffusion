//
//  SidebarItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/29/24.
//

import SwiftUI
import SwiftData

/// Represents a view for displaying stored sidebar items, including handling for small and large previews.
/// This view dynamically selects and presents thumbnail or preview images based on user interaction toggles.
/// - Parameters:
///   - item: The `SidebarItem` to display, including all associated image and model information.
struct SidebarItemView: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  let item: SidebarItem
  @State private var currentSmallThumbnailImageUrl: URL?
  @State private var currentLargeImageUrl: URL?
  
  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      if sidebarModel.smallPreviewsButtonToggled, let thumbnailUrl = thumbnailInfo?.url {
        CachedThumbnailImageView(imageUrl: thumbnailUrl, width: 70, height: 70)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(color: .black, radius: 1, x: 0, y: 1)
      }
      
      VStack(alignment: .center) {
        if sidebarModel.largePreviewsButtonToggled, let largePreviewInfo = previewInfo {
          CachedPreviewImageView(imageInfo: largePreviewInfo)
            .scaledToFill()
            .frame(width: sidebarModel.currentWidth)
            .shadow(color: .black, radius: 1, x: 0, y: 1)
            .padding(.bottom, 8)
        }
        
        Text(item.title)
          .lineLimit(2)
        
        if sidebarModel.modelNameButtonToggled, let modelName = item.prompt?.selectedModel?.name {
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
