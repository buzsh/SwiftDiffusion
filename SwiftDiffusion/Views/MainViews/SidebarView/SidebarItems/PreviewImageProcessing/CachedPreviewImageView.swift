//
//  CachedPreviewImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

struct CachedPreviewImageView: View {
  let fallbackUrl: URL
  @Binding var imageUrl: URL?
  
  @State private var displayedImage: NSImage?
  
  var body: some View {
    Group {
      if let displayedImage = displayedImage {
        Image(nsImage: displayedImage)
          .resizable()
          .scaledToFit()
      } else {
        ProgressView()
      }
    }
    .onAppear {
      loadImage()
    }
    .onChange(of: imageUrl) {
      loadImage()
    }
  }
  
  private func loadImage() {
    // Attempt to load the image from the cache first
    if let imageUrl = imageUrl, let cachedImage = ImageCache.shared.image(forKey: imageUrl.path) {
      displayedImage = cachedImage
    } else if let fallbackImage = ImageCache.shared.image(forKey: fallbackUrl.path) {
      // Use fallback image if the primary image is not available
      displayedImage = fallbackImage
    } else {
      // Load the image into the cache if it's not present
      // This part would depend on how your images are stored and accessed
      if let imageUrl = imageUrl, let image = NSImage(contentsOf: imageUrl) {
        ImageCache.shared.setImage(image, forKey: imageUrl.path)
        displayedImage = image
      } else if let fallbackImage = NSImage(contentsOf: fallbackUrl) {
        ImageCache.shared.setImage(fallbackImage, forKey: fallbackUrl.path)
        displayedImage = fallbackImage
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
  
  func loadImage(from url: URL) -> NSImage? {
    let key = url.path as NSString
    
    if let cachedImage = cache.object(forKey: key) {
      return cachedImage
    }
    
    guard let image = NSImage(contentsOf: url) else {
      return nil
    }
    
    cache.setObject(image, forKey: key)
    return image
  }
}
