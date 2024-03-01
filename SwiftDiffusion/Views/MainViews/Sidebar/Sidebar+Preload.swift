//
//  Sidebar+Preload.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/29/24.
//

import AppKit

extension Sidebar {
    /*
      .onAppear {
        preloadImages(for: sidebarViewModel.displayedItems)
        preloadImages(for: sortedWorkspaceItems)
      }
      .onChange(of: unsavedWorkspaceItems) {
        preloadImages(for: sidebarViewModel.displayedItems)
        preloadImages(for: sortedWorkspaceItems)
      }
   */
  
  func preloadImages(for items: [SidebarItem]) {
    items.forEach { item in
      // Preload main images
      /*
       item.imageUrls.forEach { imageUrl in
       preloadImage(from: imageUrl)
       }
       */
      // Preload thumbnails
      item.imageThumbnails.forEach { imageInfo in
        preloadImage(from: imageInfo.url)
      }
      // Preload previews
      item.imagePreviews.forEach { imageInfo in
        preloadImage(from: imageInfo.url)
      }
    }
  }
  
  func preloadImage(from url: URL) {
    DispatchQueue.global(qos: .background).async {
      guard ImageCache.shared.image(forKey: url.path) == nil, let image = NSImage(contentsOf: url) else { return }
      DispatchQueue.main.async {
        ImageCache.shared.setImage(image, forKey: url.path)
      }
    }
  }
  
}
