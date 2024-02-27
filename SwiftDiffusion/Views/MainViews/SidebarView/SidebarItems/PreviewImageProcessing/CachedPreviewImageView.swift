//
//  CachedPreviewImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

struct CachedPreviewImageView: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  let imageInfo: ImageInfo?
  
  @State private var displayedImage: NSImage?
  
  var body: some View {
    Group {
      if let displayedImage = displayedImage {
        Image(nsImage: displayedImage)
          .resizable()
          .scaledToFit()
          .frame(width: calculateWidth(), height: calculateHeight())
          .clipped()
      } else {
        Rectangle()
          .foregroundColor(Color.gray.opacity(0.3))
          .frame(width: calculateWidth(), height: calculateHeight())
      }
    }
    .onAppear(perform: loadImage)
  }
  
  private func calculateWidth() -> CGFloat {
    return sidebarViewModel.currentWidth
  }
  
  private func calculateHeight() -> CGFloat {
    guard let imageInfo = imageInfo else {
      return calculateWidth()
    }
    let aspectRatio = imageInfo.height / max(imageInfo.width, 1)
    return calculateWidth() * aspectRatio
  }
  
  private func loadImage() {
    guard let imageUrl = imageInfo?.url else {
      return
    }
    
    if let cachedImage = ImageCache.shared.image(forKey: imageUrl.path) {
      displayedImage = cachedImage
      return
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
      if let image = NSImage(contentsOf: imageUrl) {
        DispatchQueue.main.async {
          ImageCache.shared.setImage(image, forKey: imageUrl.path)
          self.displayedImage = image
        }
      }
    }
  }
}

class ImageCache {
  static let shared = ImageCache()
  private var cache = NSCache<NSString, NSImage>()
  
  private init() {}
  
  func image(forKey key: String) -> NSImage? {
    return cache.object(forKey: key as NSString)
  }
  
  func setImage(_ image: NSImage, forKey key: String) {
    cache.setObject(image, forKey: key as NSString)
  }
}
