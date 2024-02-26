//
//  NSImageExtensions.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import AppKit

extension NSImage {
  /// Generates JPEG data from the image after resizing it to a specified maximum dimension and applying JPEG compression.
  /// This method first resizes the image to ensure that its largest dimension does not exceed the specified `maxDimension`,
  /// maintaining the original aspect ratio. It then converts the resized image to JPEG format with a specified compression factor.
  /// - Parameters:
  ///   - maxDimension: The maximum width or height the image should have after resizing.
  ///   - compressionFactor: The compression quality to use when converting the image to JPEG format. Ranges from 0.0 (most compression) to 1.0 (least compression).
  /// - Returns: The JPEG data of the resized and compressed image, or `nil` if the image could not be processed.
  func resizedAndCompressedImageData(maxDimension: CGFloat, compressionFactor: CGFloat) -> Data? {
    guard let resizedImage = self.resizedImage(to: maxDimension),
          let tiffRepresentation = resizedImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
      return nil
    }
    return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
  }
}

extension NSImage {
  /// Resizes the image to a specified maximum dimension while maintaining its aspect ratio.
  /// The image is scaled down such that its largest dimension (width or height) matches the `maxDimension` provided,
  /// ensuring that the aspect ratio of the original image is preserved.
  /// - Parameter maxDimension: The maximum width or height the resized image should have.
  /// - Returns: A new `NSImage` instance representing the resized image, or `nil` if the image could not be resized.
  func resizedImage(to maxDimension: CGFloat) -> NSImage? {
    let originalSize = self.size
    var newSize: CGSize = .zero
    
    let widthRatio = maxDimension / originalSize.width
    let heightRatio = maxDimension / originalSize.height
    let ratio = min(widthRatio, heightRatio)
    
    newSize.width = floor(originalSize.width * ratio)
    newSize.height = floor(originalSize.height * ratio)
    
    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    self.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height),
              from: NSRect(x: 0, y: 0, width: originalSize.width, height: originalSize.height),
              operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    
    return newImage
  }
}

extension NSImage {
  /// Converts the image to JPEG format using a specified compression quality.
  /// This method generates JPEG data for the image using the provided compression factor.
  /// - Parameter compressionQuality: The desired compression quality for the JPEG encoding.
  ///   Values range from 0.0 (maximum compression, lowest quality) to 1.0 (minimum compression, highest quality).
  /// - Returns: The JPEG data of the image, or `nil` if the image could not be converted.
  func jpegData(compressionQuality: CGFloat) -> Data? {
    guard let tiffRepresentation = self.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
      return nil
    }
    return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
  }
}
