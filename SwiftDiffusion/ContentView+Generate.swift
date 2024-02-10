//
//  ContentView+Generate.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import Combine

extension Constants.Api {
  static let timeoutInterval: TimeInterval = 1000 // in seconds
  static let compositeImageCompressionFactor = 0.5 // JPEG: 0-most compression, 1.0-no compression
}

extension ContentView {
  func prepareAndSendAPIRequest() async {
    guard scriptManager.scriptState == .active, let baseUrl = scriptManager.serviceUrl else {
      Debug.log("Script is not active or URL is unavailable")
      return
    }
    
    scriptManager.genStatus = .preparingToGenerate
    scriptManager.genProgress = -1
    
    guard let sdModelCheckpoint = promptViewModel.selectedModel?.sdModelCheckpoint else { return }
    
    let overrideSettings: [String: Any] = [
      "CLIP_stop_at_last_layers": Int(promptViewModel.clipSkip)
    ]
    // "sd_model_checkpoint": sdModelCheckpoint
    
    // API payload models (might have to get hacky)
    // https://github.com/AUTOMATIC1111/stable-diffusion-webui/discussions/3734#discussioncomment-4125262
    //
    // UPDATE: POSTing to sdapi/v1/options with sd_model_checkpoint works
    // https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/4301#issuecomment-1328249975
    let payload: [String: Any] = [
      "prompt": promptViewModel.positivePrompt,
      "negative_prompt": promptViewModel.negativePrompt,
      "width": Int(promptViewModel.width),
      "height": Int(promptViewModel.height),
      "cfg_scale": Int(promptViewModel.cfgScale),
      "steps": Int(promptViewModel.samplingSteps),
      "seed": Int(promptViewModel.seed) ?? -1,
      "batch_count": Int(promptViewModel.batchCount),
      "batch_size": Int(promptViewModel.batchSize),
      "override_settings": overrideSettings,
      // extras
      "do_not_save_grid" : false,
      "do_not_save_samples" : false,
    ]
    
    Debug.log("Sending API request to \(baseUrl)\n > \(payload)")
    
    await sendAPIRequest(api: baseUrl, payload: payload)
  }
}


extension ContentView {
  func sendAPIRequest(api: URL, payload: [String: Any]) async {
    Debug.log("API base URL: \(api)")
    
    let endpoint = "sdapi/v1/txt2img"
    guard let url = URL(string: endpoint, relativeTo: api) else {
      Debug.log("Invalid URL")
      return
    }
    
    // custom URLSession configuration with increased timeout intervals
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = Constants.Api.timeoutInterval
    configuration.timeoutIntervalForResource = Constants.Api.timeoutInterval
    let session = URLSession(configuration: configuration)
    
    do {
      let requestData = try JSONSerialization.data(withJSONObject: payload, options: [])
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = requestData
      
      // use the custom URLSession to make the network request
      let (data, _) = try await session.data(for: request)
      
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let images = json["images"] as? [String] {
        
        await saveImages(base64EncodedImages: images)
      }
    } catch {
      Task { @MainActor in
        Debug.log("[ContentView] Request error: \(error)")
      }
    }
  }
}


extension ContentView {
  func saveImages(base64EncodedImages: [String]) async {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateFolderName = dateFormatter.string(from: Date())
    
    let fileManager = FileManager.default
    
    
    var directoryURL: URL = URL(fileURLWithPath: userSettingsModel.userOutputDirectoryPath).appendingPathComponent("txt2img/\(dateFolderName)")
    if !fileManager.fileExists(atPath: directoryURL.path) {
        // Fallback to using the documents directory if the specified path doesn't exist
        directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("SwiftDiffusion/txt2img/\(dateFolderName)")
    }
    
    Debug.log("saveImages.directoryURL: \(String(describing: directoryURL))")
    
    do {
      try FileUtility.ensureDirectoryExists(at: directoryURL)
    } catch {
      Debug.log("Could not ensure directory exists: \(error.localizedDescription)")
      return
    }
    
    var nextImageNumber = 1
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
    
    var imagesForComposite: [NSImage] = []
    
    for base64Image in base64EncodedImages {
      guard let imageData = Data(base64Encoded: base64Image), let nsImage = NSImage(data: imageData) else {
        Debug.log("Invalid image data")
        continue
      }
      
      imagesForComposite.append(nsImage)
      
      let filePath = directoryURL.appendingPathComponent("\(nextImageNumber).png")
      do {
        try imageData.write(to: filePath)
        Debug.log("Image saved to \(filePath)")
        nextImageNumber += 1
      } catch {
        Debug.log("Failed to save image: \(error.localizedDescription)")
      }
    }
    
    // check if more than one image is returned; if so, create and set to composite image
    if imagesForComposite.count > 1 {
      if let compositeImage = await createCompositeImage(from: imagesForComposite, withCompressionFactor: Constants.Api.compositeImageCompressionFactor) {
        let compositeImageName = "\(nextImageNumber)-grid.png"
        let compositeImagePath = directoryURL.appendingPathComponent(compositeImageName)
        guard let tiffData = compositeImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
          Debug.log("Failed to prepare composite image data")
          return
        }
        
        do {
          try pngData.write(to: compositeImagePath)
          Debug.log("Composite image saved to \(compositeImagePath)")
          
          await MainActor.run {
            self.selectedImage = compositeImage
            self.lastSelectedImagePath = compositeImagePath.path
          }
        } catch {
          Debug.log("Failed to save composite image: \(error.localizedDescription)")
        }
      }
    } else if let singleImage = imagesForComposite.first {
      // if only one image, set selectedImage and lastSelectedImagePath to that image
      let singleImagePath = directoryURL.appendingPathComponent("\(nextImageNumber - 1).png")
      await MainActor.run {
        self.selectedImage = singleImage
        self.lastSelectedImagePath = singleImagePath.path
      }
    }
    
    // update scriptManager.genStatus and Delay as previously
    scriptManager.genStatus = .done
    Delay.by(3.0) {
      scriptManager.genStatus = .idle
      scriptManager.genProgress = 0
    }
  }
}
