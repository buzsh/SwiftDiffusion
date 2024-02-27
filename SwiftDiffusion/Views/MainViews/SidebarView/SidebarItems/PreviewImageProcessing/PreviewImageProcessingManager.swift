//
//  PreviewImageProcessingManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI
import Foundation
import AppKit
import SwiftData

class PreviewImageProcessingManager {
  static let shared = PreviewImageProcessingManager()
  
  private init() {}
  
  /// Creates both image previews and thumbnails for a given sidebar item.
  /// This function first generates image previews with a specified maximum dimension and compression factor,
  /// then generates thumbnails with their own parameters.
  /// - Parameters:
  ///   - sidebarItem: The `SidebarItem` for which previews and thumbnails will be generated.
  ///   - model: The model context within which these operations are performed, allowing for data persistence.
  func createImagePreviewsAndThumbnails(for sidebarItem: SidebarItem, in model: ModelContext) {
    Debug.log("[info] Starting imageUrls: \(sidebarItem.imageUrls)")
    createImagePreviews(for: sidebarItem, in: model, maxDimension: 500, compressionFactor: 0.4)
    createImageThumbnails(for: sidebarItem, in: model, maxDimension: 100, compressionFactor: 0.4)
  }
  
  /// Generates image previews for a given sidebar item and stores them in a specified directory.
  /// This function resizes and compresses the original images to a specified maximum dimension and compression factor,
  /// then saves the processed images to the "StoredPromptPreviews" directory.
  /// - Parameters:
  ///   - sidebarItem: The `SidebarItem` for which image previews are being created.
  ///   - model: The model context used for any necessary data operations related to this process.
  ///   - maxDimension: The maximum dimension (width or height) for the previews. Defaults to 1000 pixels.
  ///   - compressionFactor: The JPEG compression factor used when saving the previews. Defaults to 0.5.
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
    
    var previewInfos: [ImageInfo] = []
    
    sidebarItem.imageUrls.forEach { imageUrl in
      guard let image = NSImage(contentsOf: imageUrl) else {
        Debug.log("[createImagePreviews] Failed to load image at \(imageUrl)")
        return
      }
      
      let (imageData, resizedImage) = image.resizedAndCompressedImageData(maxDimension: maxDimension, compressionFactor: compressionFactor)
      guard let data = imageData, let resized = resizedImage else {
        Debug.log("[createImagePreviews] Failed to process image at \(imageUrl)")
        return
      }
      
      Debug.log("basePreviewURL: \(basePreviewURL)")
      
      let originalPath = imageUrl.path
      var relativePath = originalPath.replacingOccurrences(of: outputDirectoryUrl.path, with: "")
      if relativePath.hasPrefix("/") { relativePath.removeFirst() }
      
      Debug.log("relativePath: \(relativePath)")
      
      if let dotRange = relativePath.range(of: ".", options: .backwards) {
        relativePath.removeSubrange(dotRange.lowerBound..<relativePath.endIndex)
      }
      relativePath += ".jpeg"
      
      let newImageUrl = basePreviewURL.appendingPathComponent(relativePath)
      
      do {
        let directoryUrl = newImageUrl.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
        
        try data.write(to: newImageUrl)
        let imageInfo = ImageInfo(url: newImageUrl, width: resized.size.width, height: resized.size.height)
        previewInfos.append(imageInfo)
      } catch {
        Debug.log("[createImagePreviews] Failed to save preview for \(imageUrl): \(error)")
      }
    }
    
    DispatchQueue.main.async {
      sidebarItem.imagePreviews = previewInfos
      self.saveData(in: model)
      Debug.log("[info] Finished imagePreviews: \(previewInfos.map { $0.url })")
    }
  }
  
  /// Generates thumbnails for a given sidebar item and stores them in a specified directory.
  /// This function optionally uses generated previews as a source if available; otherwise, it uses the original images.
  /// The images are resized and compressed to a specified maximum dimension and compression factor,
  /// then saved to the "StoredPromptThumbnails" directory.
  /// - Parameters:
  ///   - sidebarItem: The `SidebarItem` for which thumbnails are being created.
  ///   - model: The model context used for any necessary data operations related to this process.
  ///   - maxDimension: The maximum dimension (width or height) for the thumbnails. Defaults to 250 pixels.
  ///   - compressionFactor: The JPEG compression factor used when saving the thumbnails. Defaults to 0.5.
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
    
    var thumbnailInfos: [ImageInfo] = []
    
    let sourceImageUrls = sidebarItem.imagePreviews.isEmpty == false ?
    sidebarItem.imagePreviews.map { $0.url } : // Extract URLs from imagePreviewInfos
    sidebarItem.imageUrls // Use original URLs as fallback
    
    
    sourceImageUrls.forEach { imageUrl in
      guard let image = NSImage(contentsOf: imageUrl) else {
        Debug.log("[createImageThumbnails] Failed to load image at \(imageUrl)")
        return
      }
      
      let (imageData, resizedImage) = image.resizedAndCompressedImageData(maxDimension: maxDimension, compressionFactor: compressionFactor)
      guard let data = imageData, let resized = resizedImage else {
        Debug.log("[createImageThumbnails] Failed to process image at \(imageUrl)")
        return
      }
      
      let originalPath = imageUrl.path
      var relativePath = originalPath.replacingOccurrences(of: outputDirectoryUrl.path, with: "")
      if relativePath.hasPrefix("/") { relativePath.removeFirst() }
      
      if let dotRange = relativePath.range(of: ".", options: .backwards) {
        relativePath.removeSubrange(dotRange.lowerBound..<relativePath.endIndex)
      }
      relativePath += ".jpeg"
      
      let newImageUrl = baseThumbnailURL.appendingPathComponent(relativePath)
      
      do {
        let directoryUrl = newImageUrl.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
        
        try data.write(to: newImageUrl)
        // Note: Using resized.size might not reflect the exact dimensions due to compression, but it's a close approximation.
        let imageInfo = ImageInfo(url: newImageUrl, width: resized.size.width, height: resized.size.height)
        thumbnailInfos.append(imageInfo)
      } catch {
        Debug.log("[createImageThumbnails] Failed to save thumbnail for \(imageUrl): \(error)")
      }
    }
    
    DispatchQueue.main.async {
      sidebarItem.imageThumbnails = thumbnailInfos
      self.saveData(in: model)
      Debug.log("[info] Finished imageThumbnails: \(thumbnailInfos.map { $0.url })")
    }
  }
  
  /// Moves all preview and thumbnail assets for a given sidebar item to the trash.
  /// This function attempts to move each file referenced in the sidebarItem's imagePreviewUrls and imageThumbnailUrls to the trash.
  /// Optionally plays a sound effect when the trashing operation is completed.
  /// - Parameters:
  ///   - sidebarItem: The `SidebarItem` whose associated preview and thumbnail files are to be trashed.
  ///   - model: The model context, allowing for the update of the `SidebarItem` state within the data model.
  ///   - withSoundEffect: A boolean flag indicating whether a sound effect should be played upon completion. Defaults to false.
  func trashPreviewAndThumbnailAssets(for sidebarItem: SidebarItem, in model: ModelContext, withSoundEffect: Bool = false) {
    let fileManager = FileManager.default
    
    func moveToTrash(imageInfo: ImageInfo) {
      do {
        var resultingUrl: NSURL? = nil
        try fileManager.trashItem(at: imageInfo.url, resultingItemURL: &resultingUrl)
        Debug.log("[trashPreviewAndThumbnailAssets] Moved to trash: \(imageInfo.url)")
      } catch {
        Debug.log("[trashPreviewAndThumbnailAssets] Failed to move to trash: \(imageInfo.url), error: \(error)")
      }
    }
    
    sidebarItem.imagePreviews.forEach(moveToTrash)
    sidebarItem.imageThumbnails.forEach(moveToTrash)
    
    DispatchQueue.main.async {
      sidebarItem.imagePreviews = []
      sidebarItem.imageThumbnails = []
      self.saveData(in: model)
      
      if withSoundEffect {
        SoundUtility.play(systemSound: .trash)
      }
    }
  }
  
  /// Attempts to save changes to the model context, encapsulating any database or data storage updates.
  /// This method is designed to commit any pending modifications held within the model context to the underlying data store,
  /// ensuring that changes made to the model objects are persisted across sessions.
  /// If an error occurs during the save operation, it logs the error detail for debugging purposes.
  /// - Parameter model: The model context that contains the changes to be saved. This context represents a session
  ///   of work that can be committed to the data store.
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
}
