//
//  NSImageExtensions.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

extension NSImage {
  /// Resizes the NSImage while maintaining its original aspect ratio to match the target height.
  ///
  /// - Parameters:
  ///   - targetHeight: The desired height for the resized image.
  /// - Returns: A new NSImage instance that has been resized while maintaining the original aspect ratio.
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
