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
  
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
  /// Creates both image previews and thumbnails for a given sidebar item.
  /// This function first generates image previews with a specified maximum dimension and compression factor,
  /// then generates thumbnails with their own parameters.
  /// - Parameters:
  ///   - sidebarItem: The `SidebarItem` for which previews and thumbnails will be generated.
  ///   - model: The model context within which these operations are performed, allowing for data persistence.
  func createImagePreviewsAndThumbnails(for sidebarItem: SidebarItem, in model: ModelContext) {
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
    
    var previewUrls: [URL] = []
    
    sidebarItem.imageUrls.forEach { imageUrl in
      guard let image = NSImage(contentsOf: imageUrl) else {
        Debug.log("[createImagePreviews] Failed to load image at \(imageUrl)")
        return
      }
      
      guard let imageData = image.resizedAndCompressedImageData(maxDimension: maxDimension, compressionFactor: compressionFactor) else {
        Debug.log("[createImagePreviews] Failed to process image at \(imageUrl)")
        return
      }
      
      let originalPath = imageUrl.path
      var relativePath = originalPath.replacingOccurrences(of: outputDirectoryUrl.path, with: "")
      
      if let dotRange = relativePath.range(of: ".", options: .backwards) {
        relativePath.removeSubrange(dotRange.lowerBound..<relativePath.endIndex)
      }
      relativePath += ".jpeg"
      
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
      self.saveData(in: model)
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
    
    var thumbnailUrls: [URL] = []
    
    let sourceImageUrls = sidebarItem.imagePreviewUrls?.isEmpty == false ? sidebarItem.imagePreviewUrls! : sidebarItem.imageUrls
    
    sourceImageUrls.forEach { imageUrl in
      guard let image = NSImage(contentsOf: imageUrl) else {
        Debug.log("[createImageThumbnails] Failed to load image at \(imageUrl)")
        return
      }
      
      guard let imageData = image.resizedAndCompressedImageData(maxDimension: maxDimension, compressionFactor: compressionFactor) else {
        Debug.log("[createImageThumbnails] Failed to process image at \(imageUrl)")
        return
      }
      
      let originalPath = imageUrl.path
      var relativePath = originalPath.replacingOccurrences(of: outputDirectoryUrl.path, with: "")
      if let dotRange = relativePath.range(of: ".", options: .backwards) {
        relativePath.removeSubrange(dotRange.lowerBound..<relativePath.endIndex)
      }
      relativePath += ".jpeg"
      
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
      self.saveData(in: model)
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
