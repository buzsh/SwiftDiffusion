//
//  MockSidebarItemCreator.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import Foundation
import AppKit

class MockSidebarItemCreator {
  let sidebarModel: SidebarModel
  static var processedImageURLs: [String: URL] = [:]
  
  init(model: SidebarModel) {
    self.sidebarModel = model
  }
  
  @MainActor
  func createAndAddSidebarItem(
    title: String,
    checkpointName: String,
    checkpointPath: String = "path/to/models",
    checkpointType: StoredCheckpointModelType = .python,
    positivePrompt: String = "some, positive, prompt",
    thumbnailPath: String,
    thumbnailWidth: Int,
    thumbnailHeight: Int
  ) async {
    let checkpoint = StoredCheckpointModel(name: checkpointName, path: checkpointPath, type: checkpointType)
    let prompt = StoredPromptModel()
    prompt.positivePrompt = positivePrompt
    prompt.selectedModel = checkpoint
    
    let item = SidebarItem(title: title, imageUrls: [])
    item.set(prompt: prompt)
    
    let thumbnailURL = URL(fileURLWithPath: thumbnailPath)
    let imageInfo = ImageInfo(url: thumbnailURL, width: CGFloat(thumbnailWidth), height: CGFloat(thumbnailHeight))
    item.imageThumbnails = [imageInfo]
    item.imagePreviews = [imageInfo]
    
    self.sidebarModel.rootFolder.add(item: item)
  }
  
  @MainActor
  func createCustomSidebarItem(
    title: String,
    checkpointName: String,
    checkpointPath: String = "path/to/models",
    checkpointType: StoredCheckpointModelType = .python,
    positivePrompt: String = "some, positive, prompt",
    baseAssetName: String,
    thumbnailWidth: Int,
    thumbnailHeight: Int
  ) async {
    let checkpoint = StoredCheckpointModel(name: checkpointName, path: checkpointPath, type: checkpointType)
    let prompt = StoredPromptModel()
    prompt.positivePrompt = positivePrompt
    prompt.selectedModel = checkpoint
    
    let item = SidebarItem(title: title, imageUrls: [])
    item.set(prompt: prompt)
    
    guard let thumbnailURL = await saveAssetImageToFile(named: "\(baseAssetName)-thumbnail"),
          let previewURL = await saveAssetImageToFile(named: "\(baseAssetName)-preview") else {
      print("[MockSidebarItemCreator] Failed to get URLs for image assets")
      return
    }
    
    let imageInfoThumbnail = ImageInfo(url: thumbnailURL, width: CGFloat(thumbnailWidth), height: CGFloat(thumbnailHeight))
    let imageInfoPreview = ImageInfo(url: previewURL, width: CGFloat(thumbnailWidth), height: CGFloat(thumbnailHeight))
    item.imageThumbnails = [imageInfoThumbnail]
    item.imagePreviews = [imageInfoPreview]
    
    self.sidebarModel.rootFolder.add(item: item)
  }
  
  func saveAssetImageToFile(named imageName: String) async -> URL? {
    if let cachedURL = MockSidebarItemCreator.processedImageURLs[imageName] {
      return cachedURL
    }
    
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      print("[MockSidebarItemCreator] Application Support directory not found.")
      return nil
    }
    let destinationPath = appSupportURL
      .appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
      .appendingPathComponent("UserData").appendingPathComponent("LocalDatabase")
      .appendingPathComponent("DevAssets")
      .appendingPathComponent("\(imageName).jpeg")
    
    // Ensure the directory exists
    let directoryPath = destinationPath.deletingLastPathComponent()
    if !FileManager.default.fileExists(atPath: directoryPath.path) {
      do {
        try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("[MockSidebarItemCreator] Failed to create directory for image assets: \(error)")
        return nil
      }
    }
    
    if FileManager.default.fileExists(atPath: destinationPath.path) {
      MockSidebarItemCreator.processedImageURLs[imageName] = destinationPath
      return destinationPath
    }
    
    // Perform the image processing and file writing asynchronously
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        guard let image = NSImage(named: imageName),
              let imageData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: imageData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) else {
          print("[MockSidebarItemCreator] Failed to load or process image: \(imageName)")
          DispatchQueue.main.async {
            continuation.resume(returning: nil)
          }
          return
        }
        
        do {
          try jpegData.write(to: destinationPath)
          DispatchQueue.main.async {
            MockSidebarItemCreator.processedImageURLs[imageName] = destinationPath
            continuation.resume(returning: destinationPath)
          }
        } catch {
          print("[MockSidebarItemCreator] Failed to write image data to file: \(error)")
          DispatchQueue.main.async {
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }
  
}
