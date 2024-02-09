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
  func createCompositeImage(from images: [NSImage]) async -> NSImage? {
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
    
    // Correct way to fill a rectangle in macOS
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
    
    return finalImage
  }
}
