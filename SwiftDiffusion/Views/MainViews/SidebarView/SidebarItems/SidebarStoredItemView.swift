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
        CachedPreviewImageView(imageInfo: thumbnailInfo)
          //.resizable() // Make sure the image can be resized
          .scaledToFit()
          .frame(width: 50, height: 65)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(color: .black, radius: 1, x: 0, y: 1)
      }
      
      VStack(alignment: .leading) {
        if largePreviewsButtonToggled {
          CachedPreviewImageView(imageInfo: previewInfo)
            .scaledToFill()
            .frame(width: sidebarViewModel.currentWidth)
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
  
  var thumbnailInfo: ImageInfo? {
    item.imageThumbnails.first(where: { $0.url.lastPathComponent.contains("-grid") })
    ?? item.imageThumbnails.last
  }
  
  var previewInfo: ImageInfo? {
    item.imagePreviews.first(where: { $0.url.lastPathComponent.contains("-grid") })
    ?? item.imagePreviews.last
  }
}
