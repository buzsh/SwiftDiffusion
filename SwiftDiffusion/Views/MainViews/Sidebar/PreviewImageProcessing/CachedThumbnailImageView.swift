//
//  CachedThumbnailImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

/// A view that displays a thumbnail image from a URL, caching it for performance.
struct CachedThumbnailImageView: View {
  let imageUrl: URL
  let width: CGFloat
  let height: CGFloat
  @State private var displayedImage: NSImage?
  
  init(imageUrl: URL, width: CGFloat = 50, height: CGFloat = 65) {
    self.imageUrl = imageUrl
    self.width = width
    self.height = height
  }
  
  var body: some View {
    Group {
      if let displayedImage = displayedImage {
        Image(nsImage: displayedImage)
          .resizable()
          .scaledToFill()
          .frame(width: width, height: height)
          .clipped()
      } else {
        Rectangle()
          .foregroundColor(Color.gray.opacity(0.3))
          .frame(width: width, height: height)
      }
    }
    .onAppear(perform: loadImage)
  }
  
  /// Attempts to load the image from cache or fetches it from the URL if not cached.
  private func loadImage() {
    // Attempt to retrieve the image from cache
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
