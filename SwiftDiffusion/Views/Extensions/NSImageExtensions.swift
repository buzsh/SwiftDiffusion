//
//  NSImageExtensions.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Foundation

extension NSImage {
  func resizedToMaintainAspectRatio(targetHeight: CGFloat) -> NSImage {
    let imageSize = self.size
    let heightRatio = targetHeight / imageSize.height
    let newSize = NSSize(width: imageSize.width * heightRatio, height: targetHeight)
    
    let img = NSImage(size: newSize)
    img.lockFocus()
    self.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: NSRect.zero, operation: .copy, fraction: 1.0)
    img.unlockFocus()
    return img
  }
}
