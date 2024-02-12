//
//  ImageWindowManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import Foundation
import SwiftUI
import AppKit

class ImageWindowManager: ObservableObject {
  private var imageWindowController: NSWindowController?
  
  func openImageWindow(with image: NSImage) {
    let contentView = FullscreenImageView(image: image) {
      self.imageWindowController?.close()
      self.imageWindowController = nil // Ensure the window controller is released.
    }
    // Calculate the content rect considering the image size
    var contentRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    
    if let screen = NSScreen.main {
      let screenRect = screen.visibleFrame
      let maxWidth = screenRect.width * 0.8 // Use 80% of screen width as max to ensure margins
      let maxHeight = screenRect.height * 0.8 // Use 80% of screen height as max to ensure margins
      
      // Calculate scaling factor to fit image within screen dimensions
      let scalingFactor = min(1, min(maxWidth / image.size.width, maxHeight / image.size.height))
      
      // Apply scaling factor to contentRect size
      contentRect.size = NSSize(width: image.size.width * scalingFactor, height: image.size.height * scalingFactor)
      
      // Center the window frame within the screen
      let centerX = screenRect.origin.x + (screenRect.width - contentRect.width) / 2
      let centerY = screenRect.origin.y + (screenRect.height - contentRect.height) / 2
      contentRect.origin = CGPoint(x: centerX, y: centerY)
    }
    
    let window = NSWindow(
      contentRect: contentRect,
      styleMask: [.closable, .resizable, .miniaturizable], // Removed .titled from the style mask
      backing: .buffered, defer: false)
    window.contentView = NSHostingView(rootView: contentView)
    window.isMovableByWindowBackground = true
    window.title = "Image Preview"
    window.aspectRatio = contentRect.size // Set the aspect ratio to match the scaled image size
    
    self.imageWindowController = NSWindowController(window: window)
    self.imageWindowController?.showWindow(nil)
  }
  
}
