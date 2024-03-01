//
//  ImageCache.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import AppKit

/// A singleton class responsible for caching `NSImage` objects to improve performance and reduce network usage.
/// This class uses `NSCache` to store images keyed by their URL path, providing a simple API for accessing and storing images.
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
