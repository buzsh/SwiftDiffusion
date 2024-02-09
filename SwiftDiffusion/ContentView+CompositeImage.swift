//
//  ContentView+CompositeImage.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import Combine
import AppKit

extension ContentView {
  func createCompositeImage(from images: [NSImage], withCompressionFactor: Double = 1.0) async -> NSImage? {
    guard !images.isEmpty else { return nil }
    
    let rowCount = Int(ceil(Double(images.count) / 2.0))
    let columnCount = min(images.count, 2) // Ensures we don't calculate more columns than there are images
    
    // Assuming all images are the same size for simplicity. Adjust as needed.
    guard let firstImage = images.first else { return nil }
    guard let firstImageRep = firstImage.representations.first else { return nil }
    let imageSize = CGSize(width: firstImageRep.pixelsWide, height: firstImageRep.pixelsHigh)
    
    let finalSize = CGSize(width: imageSize.width * CGFloat(columnCount), height: imageSize.height * CGFloat(rowCount))
    
    let finalImage = NSImage(size: finalSize)
    finalImage.lockFocus()
    
    NSColor.black.setFill()
    NSRect(origin: .zero, size: finalSize).fill()
    
    for (index, image) in images.enumerated() {
      let row = index / columnCount
      let column = index % columnCount
      let xPosition = CGFloat(column) * imageSize.width
      let yPosition = CGFloat(row) * imageSize.height
      image.draw(in: NSRect(x: xPosition, y: yPosition, width: imageSize.width, height: imageSize.height))
    }
    
    finalImage.unlockFocus()
    
    // Convert the finalImage to a compressed JPEG
    guard let tiffData = finalImage.tiffRepresentation,
          let imageRep = NSBitmapImageRep(data: tiffData) else {
      Debug.log("Failed to create image representation")
      return nil
    }
    
    // Adjust the compression quality as needed (0.0 to 1.0, lower means more compression)
    let compressionQuality: CGFloat = 0.5
    guard let jpegData = imageRep.representation(using: .jpeg, properties: [.compressionFactor: withCompressionFactor]) else {
      Debug.log("Failed to compress image")
      return nil
    }
    
    return NSImage(data: jpegData)
  }
}
