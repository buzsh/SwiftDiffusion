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
      self.imageWindowController = nil
    }
    
    var contentRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    
    if let screen = NSScreen.main {
      let screenRect = screen.visibleFrame
      let maxWidth = screenRect.width * 1.0
      let maxHeight = screenRect.height * 1.0
      
      let scalingFactor = min(1, min(maxWidth / image.size.width, maxHeight / image.size.height))
      
      contentRect.size = NSSize(width: image.size.width * scalingFactor, height: image.size.height * scalingFactor)
      
      let centerX = screenRect.origin.x + (screenRect.width - contentRect.width) / 2
      let centerY = screenRect.origin.y + (screenRect.height - contentRect.height) / 2
      contentRect.origin = CGPoint(x: centerX, y: centerY)
    }
    
    let window = NSWindow(
      contentRect: contentRect,
      styleMask: [.closable, .resizable, .miniaturizable],
      backing: .buffered, defer: false)
    window.contentView = NSHostingView(rootView: contentView)
    window.isMovableByWindowBackground = true
    window.title = "Image Preview"
    window.aspectRatio = contentRect.size
    
    self.imageWindowController = NSWindowController(window: window)
    self.imageWindowController?.showWindow(nil)
    
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  
}
