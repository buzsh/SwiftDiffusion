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

// POSTing to sdapi/v1/options with sd_model_checkpoint
// https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/4301#issuecomment-1328249975

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
    
    var overrideSettings: [String: Any] = [
      "CLIP_stop_at_last_layers": Int(currentPrompt.clipSkip)
    ]
    
    if let selectedModel = currentPrompt.selectedModel, let apiModel = selectedModel.checkpointApiModel {
      overrideSettings = [
        "sd_model_checkpoint": apiModel.title,
        "CLIP_stop_at_last_layers": Int(currentPrompt.clipSkip)
      ]
    }
    
    payload[PayloadKey.overrideSettings.rawValue] = overrideSettings
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      scriptManager.mostRecentApiRequestPayload = jsonString
    } else {
      Debug.log("Failed to serialize payload to JSON string")
      scriptManager.mostRecentApiRequestPayload = "{}"
    }
    
    return payload
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
  
  private func updateUIWithImageResult(_ result: (Data?, String, [URL])) async {
    let (imageData, imagePath, savedImageUrls) = result
    let image: NSImage? = imageData.flatMap { NSImage(data: $0) }
    
    await MainActor.run {
      self.selectedImage = image
      self.lastSelectedImagePath = imagePath
      self.lastSavedImageUrls = savedImageUrls
      scriptManager.genStatus = .done
      
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
    
    let payload = prepareImageGenerationPayloadFromPrompt()
    
    guard let baseAPI = scriptManager.serviceUrl else {
      Debug.log("Invalid base API URL")
      return
    }
    
    Task {
      guard let images = await Txt2ImgService.shared.sendImageGenerationRequest(to: .txt2img, with: payload, baseAPI: baseAPI) else {
        Debug.log("Failed to fetch images from API")
        return
      }
      
      saveGeneratedImages(base64EncodedImages: images)
    }
  }
}
