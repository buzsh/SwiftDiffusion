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
    createImagePreviews(for: sidebarItem, in: model, maxDimension: 1000, compressionFactor: 0.5)
    createImageThumbnails(for: sidebarItem, in: model, maxDimension: 250, compressionFactor: 0.5)
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
    guard let resizedImage = self.resizedImage(maxDimension: maxDimension),
          let tiffRepresentation = resizedImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
      return nil
    }
    return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
  }
  
  func resizedImage(maxDimension: CGFloat) -> NSImage? {
    var newSize: CGSize = .zero
    let width = self.size.width
    let height = self.size.height
    
    let aspectRatio = width / height
    if width > height {
      newSize.width = maxDimension
      newSize.height = maxDimension / aspectRatio
    } else {
      newSize.height = maxDimension
      newSize.width = maxDimension * aspectRatio
    }
    
    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    self.draw(in: CGRect(origin: .zero, size: newSize), from: CGRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    
    return newImage
  }
}



extension NSImage {
  func jpegData(compressionQuality: CGFloat) -> Data? {
    guard let resizedImage = self.resizedImage(maxDimension: 250),
          let tiffRepresentation = resizedImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
      return nil
    }
    return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
  }
}
