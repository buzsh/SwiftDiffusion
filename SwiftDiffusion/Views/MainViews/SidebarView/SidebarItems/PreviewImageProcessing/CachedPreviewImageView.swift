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
    // Reset the displayed image to nil to ensure the progress view is shown during loading
    displayedImage = nil
    
    // Attempt to load the image from the cache first
    if let imageUrl = imageUrl, let cachedImage = ImageCache.shared.image(forKey: imageUrl.path) {
      displayedImage = cachedImage
    } else {
      // Attempt to load fallback image from cache if primary image is not available
      if let fallbackImage = ImageCache.shared.image(forKey: fallbackUrl.path) {
        displayedImage = fallbackImage
      }
      
      // Load the primary or fallback image into the cache if it's not present
      loadAndCacheImage(url: imageUrl ?? fallbackUrl)
    }
  }
  
  private func loadAndCacheImage(url: URL) {
    // Asynchronous loading and caching of the image
    DispatchQueue.global(qos: .userInitiated).async {
      if let image = NSImage(contentsOf: url) {
        DispatchQueue.main.async {
          ImageCache.shared.setImage(image, forKey: url.path)
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
