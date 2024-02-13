//
//  ContentView+Generate.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import Combine

extension Constants {
  enum API {
    static let timeoutInterval: TimeInterval = 1000
    static let compositeImageCompressionFactor: Double = 0.5
    
    enum Endpoint: String {
      case txt2img = "sdapi/v1/txt2img"
      
      var outputDirName: String {
        switch self {
        case .txt2img: return "txt2img"
        }
      }
      
      func url(relativeTo base: URL) -> URL? {
        return URL(string: self.rawValue, relativeTo: base)
      }
    }
  }
}

enum PayloadKey: String {
  case prompt
  case negativePrompt = "negative_prompt"
  case width
  case height
  case cfgScale = "cfg_scale"
  case steps
  case seed
  case batchCount = "batch_count"
  case batchSize = "batch_size"
  case overrideSettings = "override_settings"
  case doNotSaveGrid = "do_not_save_grid"
  case doNotSaveSamples = "do_not_save_samples"
}

class APIService {
  static let shared = APIService()
  
  private init() {}
  
  func sendImageGenerationRequest(to endpoint: Constants.API.Endpoint, with payload: [String: Any], baseAPI: URL) async -> [String]? {
    guard let url = endpoint.url(relativeTo: baseAPI) else {
      Debug.log("Invalid URL for endpoint: \(endpoint)")
      return nil
    }
    
    do {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
      
      let session = URLSession(configuration: self.customSessionConfiguration())
      let (data, _) = try await session.data(for: request)
      
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let images = json["images"] as? [String] {
        return images
      }
    } catch {
      Debug.log("API request failed with error: \(error)")
    }
    return nil
  }
  
  private func customSessionConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = Constants.API.timeoutInterval
    configuration.timeoutIntervalForResource = Constants.API.timeoutInterval
    return configuration
  }
}

extension ContentView {
  func prepareImageGenerationPayloadFromPrompt() -> [String: Any] {
    var payload: [String: Any] = [
      PayloadKey.prompt.rawValue: currentPrompt.positivePrompt,
      PayloadKey.negativePrompt.rawValue: currentPrompt.negativePrompt,
      PayloadKey.width.rawValue: Int(currentPrompt.width),
      PayloadKey.height.rawValue: Int(currentPrompt.height),
      PayloadKey.cfgScale.rawValue: Int(currentPrompt.cfgScale),
      PayloadKey.steps.rawValue: Int(currentPrompt.samplingSteps),
      PayloadKey.seed.rawValue: Int(currentPrompt.seed) ?? -1,
      PayloadKey.batchCount.rawValue: Int(currentPrompt.batchCount),
      PayloadKey.batchSize.rawValue: Int(currentPrompt.batchSize),
      PayloadKey.doNotSaveGrid.rawValue: false,
      PayloadKey.doNotSaveSamples.rawValue : false
    ]
    
    let overrideSettings: [String: Any] = [
      "CLIP_stop_at_last_layers": Int(currentPrompt.clipSkip)
    ]
    
    payload[PayloadKey.overrideSettings.rawValue] = overrideSettings
    return payload
  }
}

struct ImageSaver {
  static func saveImages(images base64EncodedImages: [String], to directoryURL: URL) async -> (Data?, String) {
          let fileManager = FileManager.default
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
              
              // Directly save each image if not creating a composite
              if base64EncodedImages.count == 1 {
                  let filePath = directoryURL.appendingPathComponent("\(nextImageNumber).png")
                  do {
                      try imageData.write(to: filePath)
                      Debug.log("Image saved to \(filePath)")
                      return (imageData, filePath.path)
                  } catch {
                      Debug.log("Failed to save image: \(error.localizedDescription)")
                      return (nil, "")
                  }
              }
          }
          
          // Proceed to create a composite image if there are multiple images
          if imagesForComposite.count > 1 {
              if let compositeImageData = await createCompositeImageData(from: imagesForComposite, withCompressionFactor: Constants.API.compositeImageCompressionFactor) {
                  let compositeImageName = "\(nextImageNumber)-grid.png"
                  let compositeImagePath = directoryURL.appendingPathComponent(compositeImageName)
                  do {
                      try compositeImageData.write(to: compositeImagePath)
                      Debug.log("Composite image saved to \(compositeImagePath)")
                      return (compositeImageData, compositeImagePath.path)
                  } catch {
                      Debug.log("Failed to save composite image: \(error.localizedDescription)")
                      return (nil, "")
                  }
              }
          }

          return (nil, "")
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

extension ContentView {
  func saveGeneratedImages(base64EncodedImages: [String]) {
    guard let directoryURL = ImageSaver.getOutputDirectoryUrl(forEndpoint: .txt2img) else {
      Debug.log("[saveGeneratedImages] error outputUrl")
      return
    }
    
    Task {
      let result = await ImageSaver.saveImages(images: base64EncodedImages, to: directoryURL)
      await updateUIWithImageResult(result)
    }
  }
  
  private func updateUIWithImageResult(_ result: (Data?, String)) async {
    let (imageData, imagePath) = result
    // Convert Data? to NSImage?
    let image: NSImage? = imageData.flatMap { NSImage(data: $0) }
    
    await MainActor.run {
      self.selectedImage = image
      self.lastSelectedImagePath = imagePath
      
      // Update scriptManager and other states as needed
      scriptManager.genStatus = .done
      scriptManager.genStatus = .idle
      scriptManager.genProgress = 0
      
      Delay.by(3) {
        scriptManager.genStatus = .idle
        scriptManager.genProgress = 0
      }
    }
  }
}

extension ContentView {
  func fetchAndSaveGeneratedImages() {
    scriptManager.genStatus = .preparingToGenerate
    scriptManager.genProgress = -1
    
    let payload = prepareImageGenerationPayloadFromPrompt() // Assuming this prepares your API request payload correctly
    
    guard let baseAPI = scriptManager.serviceUrl else {
      Debug.log("Invalid base API URL")
      return
    }
    
    Task {
      guard let images = await APIService.shared.sendImageGenerationRequest(to: .txt2img, with: payload, baseAPI: baseAPI) else {
        Debug.log("Failed to fetch images from API")
        return
      }
      
      // Assuming `images` are the base64 encoded strings you need to save
      saveGeneratedImages(base64EncodedImages: images)
    }
  }
}




/*
 extension ContentView {
 func prepareAndSendAPIRequest() async {
 guard scriptManager.scriptState == .active, let baseUrl = scriptManager.serviceUrl else {
 Debug.log("Script is not active or URL is unavailable")
 return
 }
 
 scriptManager.genStatus = .preparingToGenerate
 scriptManager.genProgress = -1
 
 let overrideSettings: [String: Any] = [
 "CLIP_stop_at_last_layers": Int(currentPrompt.clipSkip)
 ]
 // "sd_model_checkpoint": sdModelCheckpoint
 
 // API payload models (might have to get hacky)
 // https://github.com/AUTOMATIC1111/stable-diffusion-webui/discussions/3734#discussioncomment-4125262
 //
 // UPDATE: POSTing to sdapi/v1/options with sd_model_checkpoint works
 // https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/4301#issuecomment-1328249975
 let payload: [String: Any] = [
 "prompt": currentPrompt.positivePrompt,
 "negative_prompt": currentPrompt.negativePrompt,
 "width": Int(currentPrompt.width),
 "height": Int(currentPrompt.height),
 "cfg_scale": Int(currentPrompt.cfgScale),
 "steps": Int(currentPrompt.samplingSteps),
 "seed": Int(currentPrompt.seed) ?? -1,
 "batch_count": Int(currentPrompt.batchCount),
 "batch_size": Int(currentPrompt.batchSize),
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
 configuration.timeoutIntervalForRequest = Constants.API.timeoutInterval
 configuration.timeoutIntervalForResource = Constants.API.timeoutInterval
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
 */

/*
 extension ContentView {
 func saveImages(base64EncodedImages: [String]) async {
 let dateFormatter = DateFormatter()
 dateFormatter.dateFormat = "yyyy-MM-dd"
 let dateFolderName = dateFormatter.string(from: Date())
 
 guard let baseDirectoryURL = UserSettings.shared.outputDirectoryUrl else {
 Debug.log("Unable to get base directory URL from UserSettings.")
 return
 }
 
 // Append the "txt2img/\(dateFolderName)" to the base directory URL
 let finalDirectoryURL = baseDirectoryURL.appendingPathComponent("txt2img/\(dateFolderName)")
 
 // Ensure this final directory exists
 do {
 try FileUtility.ensureDirectoryExists(at: finalDirectoryURL)
 } catch {
 Debug.log("Could not ensure directory exists: \(error.localizedDescription)")
 return
 }
 
 Debug.log("saveImages.directoryURL: \(finalDirectoryURL)")
 
 let fileManager = FileManager.default
 var nextImageNumber = 1
 do {
 let fileURLs = try fileManager.contentsOfDirectory(at: finalDirectoryURL, includingPropertiesForKeys: nil)
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
 
 let filePath = finalDirectoryURL.appendingPathComponent("\(nextImageNumber).png")
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
 let compositeImagePath = finalDirectoryURL.appendingPathComponent(compositeImageName)
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
 let singleImagePath = finalDirectoryURL.appendingPathComponent("\(nextImageNumber - 1).png")
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
 */
