//
//  ThumbnailLoader.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Cocoa
import SwiftUI

class ThumbnailLoader: ObservableObject {
  @Published var thumbnailImage: NSImage?
  @Published var imageSize: CGSize?
  @Published var fileSize: String = ""
  
  func loadThumbnail(for node: FileNode) async {
    await processImage(from: node.fullPath)
    await fetchAndSetFileSize(for: node.fullPath)
  }
  
  @MainActor
  private func processImage(from path: String) {
    guard let image = NSImage(contentsOfFile: path) else {
      self.thumbnailImage = nil
      return
    }
    
    let thumbnail = image.resizedToMaintainAspectRatio(targetHeight: 40)
    self.thumbnailImage = thumbnail
    self.imageSize = image.size
  }
  
  private func fetchAndSetFileSize(for path: String) async {
    do {
      let fileSizeAttributes = try FileManager.default.attributesOfItem(atPath: path)
      if let fileSize = fileSizeAttributes[.size] as? NSNumber {
        await MainActor.run {
          self.fileSize = formatFileSize(fileSize.intValue)
        }
      }
    } catch {
      Debug.log("[ThumbnailLoader] fetchAndSetFileSize(for: \(path))\n > Error fetching file size: \(error)")
    }
  }
  
  private func formatFileSize(_ size: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(size))
  }
}
