//
//  CachedPreviewImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

struct CachedPreviewImageView: View {
  let imageUrl: URL
  
  @State private var displayedImage: NSImage?
  
  var body: some View {
    Group {
      if let displayedImage = displayedImage {
        Image(nsImage: displayedImage)
          .resizable()
          //.scaledToFit()
      } else {
        ProgressView()
          .onAppear(perform: loadImage)
      }
    }
  }
  
  private func loadImage() {
    // Check if the image is already cached
    if let cachedImage = ImageCache.shared.image(forKey: imageUrl.path) {
      displayedImage = cachedImage
      return
    }
    
    // Load and cache the image if not in cache
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
