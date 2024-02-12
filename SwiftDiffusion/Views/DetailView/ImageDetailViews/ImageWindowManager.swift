//
//  ImageWindowManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import Foundation
import SwiftUI

class ImageWindowManager: ObservableObject {
  private var imageWindowController: NSWindowController?
  
  func openImageWindow(with image: NSImage) {
    let contentView = FullscreenImageView(image: image) {
      self.imageWindowController?.close()
      self.imageWindowController = nil // Ensure the window controller is released.
    }
    
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered, defer: false)
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
    window.center() // Optional: Center the window on screen.
    window.title = "Image Preview"
    
    self.imageWindowController = NSWindowController(window: window)
  }
}
