//
//  ThumbnailLoader.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

class ThumbnailLoader: ObservableObject {
  @Published var thumbnailImage: NSImage?
  @Published var imageSize: CGSize?
  @Published var fileSize: String = ""
  
  func loadThumbnail(for node: FileNode) {
    DispatchQueue.global(qos: .userInitiated).async {
      //let fileURL = URL(fileURLWithPath: node.fullPath)
      guard let image = NSImage(contentsOfFile: node.fullPath) else {
        DispatchQueue.main.async {
          self.thumbnailImage = NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) ?? NSImage()
        }
        return
      }
      
      let thumbnail = image.resizedToMaintainAspectRatio(targetHeight: 40)
      
      // Fetch and format file size
      let fileSizeAttributes = try? FileManager.default.attributesOfItem(atPath: node.fullPath)
      if let fileSize = fileSizeAttributes?[.size] as? NSNumber {
        DispatchQueue.main.async {
          self.fileSize = self.formatFileSize(fileSize.intValue)
        }
      }
      
      DispatchQueue.main.async {
        self.thumbnailImage = thumbnail
        self.imageSize = image.size // original image size
      }
    }
  }
  
  private func formatFileSize(_ size: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(size))
  }
}
