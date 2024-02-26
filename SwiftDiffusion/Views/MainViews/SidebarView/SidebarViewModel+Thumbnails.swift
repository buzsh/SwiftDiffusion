//
//  SidebarViewModel+Thumbnails.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI
import Foundation
import AppKit
import SwiftData

extension SidebarViewModel {
  func createImagePreviewsAndThumbnails(for sidebarItem: SidebarItem, in model: ModelContext) {
    createImagePreviews(for: sidebarItem, in: model, maxDimension: 800, compressionFactor: 0.5)
    createImageThumbnails(for: sidebarItem, in: model, maxDimension: 250, compressionFactor: 0.5)
  }
}

extension SidebarViewModel {
  func trashPreviewAndThumbnailAssets(for sidebarItem: SidebarItem, in model: ModelContext, withSoundEffect: Bool = false) {
    let fileManager = FileManager.default
    
    func moveToTrash(url: URL) {
      do {
        var resultingUrl: NSURL? = nil
        try fileManager.trashItem(at: url, resultingItemURL: &resultingUrl)
        Debug.log("[trashPreviewAndThumbnailAssets] Moved to trash: \(url)")
      } catch {
        Debug.log("[trashPreviewAndThumbnailAssets] Failed to move to trash: \(url), error: \(error)")
      }
    }
    
    sidebarItem.imagePreviewUrls?.forEach(moveToTrash)
    sidebarItem.imageThumbnailUrls?.forEach(moveToTrash)
    
    DispatchQueue.main.async {
      sidebarItem.imagePreviewUrls = nil
      sidebarItem.imageThumbnailUrls = nil
      self.saveData(in: model)
      
      if withSoundEffect {
        SoundUtility.play(systemSound: .trash)
      }
    }
  }
}


extension SidebarViewModel {
  func createImagePreviews(for sidebarItem: SidebarItem, in model: ModelContext, maxDimension: CGFloat = 1000, compressionFactor: CGFloat = 0.5) {
    let fileManager = FileManager.default
    guard let outputDirectoryUrl = UserSettings.shared.outputDirectoryUrl,
          let basePreviewURL = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
            .appendingPathComponent("UserData")
            .appendingPathComponent("LocalDatabase")
            .appendingPathComponent("StoredPromptPreviews") else {
      Debug.log("[createImagePreviews] Unable to find or create the application support directory.")
      return
    }
    
    var previewUrls: [URL] = []
    
    sidebarItem.imageUrls.forEach { imageUrl in
      guard let image = NSImage(contentsOf: imageUrl) else {
        Debug.log("[createImagePreviews] Failed to load image at \(imageUrl)")
        return
      }
      
      // Resize the image and compress it to JPEG with the specified parameters
      guard let imageData = image.resizedAndCompressedImageData(maxDimension: maxDimension, compressionFactor: compressionFactor) else {
        Debug.log("[createImagePreviews] Failed to process image at \(imageUrl)")
        return
      }
      
      let relativePath = imageUrl.path.replacingOccurrences(of: outputDirectoryUrl.path, with: "")
      let newImageUrl = basePreviewURL.appendingPathComponent(relativePath)
      
      do {
        let directoryUrl = newImageUrl.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
        
        try imageData.write(to: newImageUrl)
        previewUrls.append(newImageUrl)
      } catch {
        Debug.log("[createImagePreviews] Failed to save preview for \(imageUrl): \(error)")
      }
    }
    
    DispatchQueue.main.async {
      sidebarItem.imagePreviewUrls = previewUrls
      // Implement any necessary model update logic here, such as saving changes to the model context
      self.saveData(in: model)
    }
  }
}

extension SidebarViewModel {
  func createImageThumbnails(for sidebarItem: SidebarItem, in model: ModelContext, maxDimension: CGFloat = 250, compressionFactor: CGFloat = 0.5) {
    let fileManager = FileManager.default
    guard let outputDirectoryUrl = UserSettings.shared.outputDirectoryUrl,
          let baseThumbnailURL = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
      .appendingPathComponent("UserData")
      .appendingPathComponent("LocalDatabase")
      .appendingPathComponent("StoredPromptThumbnails") else {
      Debug.log("[createImageThumbnails] Unable to find or create the application support directory.")
      return
    }
    
    var thumbnailUrls: [URL] = []
    
    // Determine which set of URLs to use for generating thumbnails
    let sourceImageUrls = sidebarItem.imagePreviewUrls?.isEmpty == false ? sidebarItem.imagePreviewUrls! : sidebarItem.imageUrls
    
    sourceImageUrls.forEach { imageUrl in
      guard let image = NSImage(contentsOf: imageUrl) else {
        Debug.log("[createImageThumbnails] Failed to load image at \(imageUrl)")
        return
      }
      
      // Resize the image and compress it to JPEG with the specified parameters
      guard let imageData = image.resizedAndCompressedImageData(maxDimension: maxDimension, compressionFactor: compressionFactor) else {
        Debug.log("[createImageThumbnails] Failed to process image at \(imageUrl)")
        return
      }
      
      let relativePath = imageUrl.path.replacingOccurrences(of: outputDirectoryUrl.path, with: "")
      let newImageUrl = baseThumbnailURL.appendingPathComponent(relativePath)
      
      do {
        let directoryUrl = newImageUrl.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
        
        try imageData.write(to: newImageUrl)
        thumbnailUrls.append(newImageUrl)
      } catch {
        Debug.log("[createImageThumbnails] Failed to save thumbnail for \(imageUrl): \(error)")
      }
    }
    
    DispatchQueue.main.async {
      sidebarItem.imageThumbnailUrls = thumbnailUrls
      // Implement any necessary model update logic here
      self.saveData(in: model)
    }
  }
}

extension NSImage {
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
  func jpegData(compressionQuality: CGFloat) -> Data? {
    guard let tiffRepresentation = self.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
      return nil
    }
    return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
  }
}
