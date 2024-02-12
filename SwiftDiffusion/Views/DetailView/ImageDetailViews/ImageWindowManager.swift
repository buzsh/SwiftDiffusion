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
    
    let aspectRatio = NSSize(width: image.size.width, height: image.size.height)
    // Calculate the content rect considering the image size
    let contentRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    
    let window = NSWindow(
      contentRect: contentRect,
      styleMask: [.closable, .resizable, .miniaturizable], // Removed .titled from the style mask
      backing: .buffered, defer: false)
    window.contentView = NSHostingView(rootView: contentView)
    window.isMovableByWindowBackground = true // Allows the window to be moved by dragging its background
    window.title = "Image Preview"
    window.aspectRatio = aspectRatio // Set the aspect ratio to match the image
    
    // Calculate the center position and adjust the window frame before displaying
    if let screen = NSScreen.main {
      let screenRect = screen.visibleFrame
      let windowSize = window.frame.size
      let centerX = screenRect.origin.x + (screenRect.width - windowSize.width) / 2
      let centerY = screenRect.origin.y + (screenRect.height - windowSize.height) / 2
      let centerFrame = NSRect(x: centerX, y: centerY, width: windowSize.width, height: windowSize.height)
      
      window.setFrame(centerFrame, display: true)
    }
    
    self.imageWindowController = NSWindowController(window: window)
    self.imageWindowController?.showWindow(nil)
  }
  
  
}
