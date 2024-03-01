//
//  CachedPreviewImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

/// A view responsible for displaying an image, either from cache or by loading it asynchronously.
/// This view supports displaying a placeholder until the image is loaded and caches the image once loaded.
/// - Parameters:
///   - imageInfo: An optional `ImageInfo` object containing the image URL and its dimensions. Used for calculating aspect ratio and size if available.
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
          .clipShape(RoundedRectangle(cornerRadius: 12))
      } else {
        Rectangle()
          .foregroundColor(Color.gray.opacity(0.3))
          .frame(width: calculateWidth(), height: calculateHeight())
      }
    }
    .onAppear(perform: loadImage)
  }
  
  /// Calculates the width of the image to be displayed, based on the current width available in the sidebar view model.
  /// - Returns: The calculated width as a `CGFloat`.
  private func calculateWidth() -> CGFloat {
    return sidebarViewModel.currentWidth
  }
  
  /// Calculates the height of the image to be displayed, utilizing the aspect ratio defined in `ImageInfo` if available.
  /// If no `ImageInfo` is available, defaults to a square based on the width.
  /// - Returns: The calculated height as a `CGFloat`.
  private func calculateHeight() -> CGFloat {
    guard let imageInfo = imageInfo else {
      return calculateWidth()
    }
    let aspectRatio = imageInfo.height / max(imageInfo.width, 1)
    return calculateWidth() * aspectRatio
  }
  
  /// Loads the image either from the cache or by fetching it asynchronously if not present in the cache.
  /// Upon successful loading, the image is cached for future use.
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

