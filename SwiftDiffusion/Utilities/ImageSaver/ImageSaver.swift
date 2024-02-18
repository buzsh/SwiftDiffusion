//
//  ImageSaver.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import AppKit

struct ImageSaver {
  static func saveImages(images base64EncodedImages: [String], to directoryURL: URL) async -> (Data?, String, [URL]) {
    let fileManager = FileManager.default
    var nextImageNumber = 1
    var outputImageUrlList: [URL] = []
    do {
      let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
      let imageFiles = fileURLs.filter { $0.pathExtension == "png" }
      let cleanGridName = imageFiles.map { $0.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "-grid", with: "") }
      let imageNumbers = cleanGridName.compactMap { Int($0) }
      if let maxNumber = imageNumbers.max() {
        nextImageNumber = maxNumber + 1
      }
    } catch {
      Debug.log("Error listing directory contents: \(error.localizedDescription)")
    }
    
    // Handle logic for single image generation (batch count == 1)
    if base64EncodedImages.count == 1 {
      guard let imageData = Data(base64Encoded: base64EncodedImages.first!), let _ = NSImage(data: imageData) else {
        Debug.log("Invalid image data for the single image")
        return (nil, "", outputImageUrlList)
      }
      
      let filePath = directoryURL.appendingPathComponent("\(nextImageNumber).png")
      do {
        try imageData.write(to: filePath)
        Debug.log("Single image saved to \(filePath)")
        outputImageUrlList.append(filePath)
        return (imageData, filePath.path, outputImageUrlList)
      } catch {
        Debug.log("Failed to save single image \("\(nextImageNumber).png") to \(filePath): \(error.localizedDescription)")
        return (nil, "", outputImageUrlList)
      }
    } else {
      
      // Handle logic for multiple images generated (batch count > 1)
      var imagesForComposite: [NSImage] = []
      let alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
      
      for (index, base64Image) in base64EncodedImages.enumerated() {
        guard let imageData = Data(base64Encoded: base64Image), let nsImage = NSImage(data: imageData) else {
          Debug.log("Invalid image data")
          continue
        }
        
        imagesForComposite.append(nsImage)
        
        if index < alphabet.count {
          // Save individual images
          let individualFileName = "\(nextImageNumber)\(alphabet[index]).png"
          let individualFilePath = directoryURL.appendingPathComponent(individualFileName)
          do {
            try imageData.write(to: individualFilePath)
            Debug.log("Individual image saved to \(individualFilePath)")
            outputImageUrlList.append(individualFilePath)
          } catch {
            Debug.log("Failed to save image \(individualFileName) to \(individualFilePath): \(error.localizedDescription)")
            // Optionally, return or handle the error
          }
        } else {
          Debug.log("Index exceeds alphabet array bounds, cannot save more individual images uniquely.")
        }
      }
      
      // Create and save the composite image
      if let compositeImageData = await createCompositeImageData(from: imagesForComposite, withCompressionFactor: Constants.API.compositeImageCompressionFactor) {
        let compositeImageName = "\(nextImageNumber)-grid.png"
        let compositeImagePath = directoryURL.appendingPathComponent(compositeImageName)
        do {
          try compositeImageData.write(to: compositeImagePath)
          Debug.log("Composite image saved to \(compositeImagePath)")
          outputImageUrlList.append(compositeImagePath)
          return (compositeImageData, compositeImagePath.path, outputImageUrlList)
        } catch {
          Debug.log("Failed to save composite image \(compositeImageName) to \(compositeImagePath): \(error.localizedDescription)")
          return (nil, "", outputImageUrlList)
        }
      }
    }
    
    return (nil, "", outputImageUrlList)
  }
  
  static func getOutputDirectoryUrl(forEndpoint endpoint: Constants.API.Endpoint) -> URL? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateFolderName = dateFormatter.string(from: Date())
    
    guard let baseDirectoryURL = UserSettings.shared.outputDirectoryUrl else {
      Debug.log("Unable to get base directory URL from UserSettings.")
      return nil
    }
    
    // Append the "txt2img/\(dateFolderName)" to the base directory URL
    //let finalDirectoryURL = baseDirectoryURL.appendingPathComponent("txt2img/\(dateFolderName)")
    let finalDirectoryURL = baseDirectoryURL.appendingPathComponent("\(endpoint.outputDirName)/\(dateFolderName)")
    
    // Ensure this final directory exists
    do {
      try FileUtility.ensureDirectoryExists(at: finalDirectoryURL)
    } catch {
      Debug.log("Could not ensure directory exists: \(error.localizedDescription)")
      return nil
    }
    
    Debug.log("saveImages.directoryURL: \(finalDirectoryURL)")
    return finalDirectoryURL
  }
}
