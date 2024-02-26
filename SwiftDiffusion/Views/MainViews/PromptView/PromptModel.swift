//
//  PromptModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Combine

extension Constants {
  static let coreMLSamplingMethods = ["DPM-Solver++", "PLMS"]
  static let pythonSamplingMethods = [
    "DPM++ 2M Karras", "DPM++ SDE Karras", "DPM++ 2M SDE Exponential", "DPM++ 2M SDE Karras", "Euler a", "Euler", "LMS", "Heun", "DPM2", "DPM2 a", "DPM++ 2S a", "DPM++ 2M", "DPM++ SDE", "DPM++ 2M SDE", "DPM++ 2M SDE Heun", "DPM++ 2M SDE Heun Karras", "DPM++ 2M SDE Heun Exponential", "DPM++ 3M SDE", "DPM++ 3M SDE Karras", "DPM++ 3M SDE Exponential", "DPM fast", "DPM adaptive", "LMS Karras", "DPM2 Karras", "DPM2 a Karras", "DPM++ 2S a Karras", "Restart", "DDIM", "PLMS", "UniPC", "LCM"
  ]
}

@MainActor
class PromptModel: ObservableObject {
  @Published var isWorkspaceItem: Bool = true
  @Published var selectedModel: CheckpointModel?
  @Published var samplingMethod: String?
  @Published var positivePrompt: String = ""
  @Published var negativePrompt: String = ""
  @Published var width: Double = 512
  @Published var height: Double = 512
  @Published var cfgScale: Double = 7
  @Published var samplingSteps: Double = 20
  @Published var seed: String = "-1"
  @Published var batchCount: Double = 1
  @Published var batchSize: Double = 1
  @Published var clipSkip: Double = 1
  // Additional Settings
  @Published var vaeModel: VaeModel?
  
  func updateVaeModel(with name: String, in vaeModelsManager: ModelManager<VaeModel>) {
    if let matchingModel = vaeModelsManager.models.first(where: { $0.name == name }) {
      self.vaeModel = matchingModel
    } else {
      Debug.log("No VAE Model found with the name \(name)")
    }
  }
}

extension PromptModel {
  func updateProperties(from model: PromptModel) {
    Debug.log("updateProperties from\n        selectedModel: \(String(describing: selectedModel?.name))")
    Debug.log("        checkpointMetadata.title: \(String(describing: selectedModel?.checkpointApiModel?.title))")
    self.isWorkspaceItem = model.isWorkspaceItem
    self.selectedModel = model.selectedModel
    self.samplingMethod = model.samplingMethod
    self.positivePrompt = model.positivePrompt
    self.negativePrompt = model.negativePrompt
    self.width = model.width
    self.height = model.height
    self.cfgScale = model.cfgScale
    self.samplingSteps = model.samplingSteps
    self.seed = model.seed
    self.batchCount = model.batchCount
    self.batchSize = model.batchSize
    self.clipSkip = model.clipSkip
    // Additional Settings
    self.vaeModel = model.vaeModel
  }
}



extension PromptModel {
  func copyMetadataToClipboard() {
    CopyPasteUtility.copyToClipboard(getSharablePromptMetadata())
  }
  
  private func getSharablePromptMetadata() -> String {
    var modelName = ""
    if let name = selectedModel?.name { modelName = name }
    var samplerName = ""
    if let samplingMethod = samplingMethod { samplerName = samplingMethod }
    
    var promptMetadata = "\(positivePrompt)\n"
    promptMetadata += "Negative prompt: \(negativePrompt)\n"
    promptMetadata += "Model: \(modelName)\n"
    promptMetadata += "Sampler: \(samplerName)\n"
    promptMetadata += "Size: \(width)x\(height)\n"
    promptMetadata += "CFG scale: \(cfgScale)\n"
    promptMetadata += "Steps: \(samplingSteps)\n"
    promptMetadata += "Clip skip: \(clipSkip)\n"
    promptMetadata += "Seed: \(seed)\n"
    promptMetadata += "Batch count: \(batchCount)\n"
    promptMetadata += "Batch size: \(batchSize)\n"
    promptMetadata += "VAE: \(vaeModel)\n"
    return promptMetadata
  }
}

/*
extension PromptModel {
  @Published var selectedModel: CheckpointModel? {
    didSet {
      updatePromptPreferences()
    }
  }
  
  private func updatePromptPreferences() {
    guard let model = selectedModel else { return }
    samplingMethod = model.preferences.samplingMethod
    if width == 512 && height == 512 {
      width = model.preferences.width
      height = model.preferences.height
    }
    cfgScale = model.preferences.cfgScale
    samplingSteps = model.preferences.samplingSteps
    batchCount = model.preferences.batchCount
    batchSize = model.preferences.batchSize
    clipSkip = model.preferences.clipSkip
  }
}
*/
