//
//  StoredPromptModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class StoredPromptModel {
  @Attribute var samplingMethod: String?
  @Attribute var positivePrompt: String = ""
  @Attribute var negativePrompt: String = ""
  @Attribute var width: Double = 512
  @Attribute var height: Double = 512
  @Attribute var cfgScale: Double = 7
  @Attribute var samplingSteps: Double = 20
  @Attribute var seed: String = "-1"
  @Attribute var batchCount: Double = 1
  @Attribute var batchSize: Double = 1
  @Attribute var clipSkip: Double = 1
  @Relationship var selectedModel: StoredCheckpointModel?
  @Relationship var vaeModel: StoredVaeModel?

  init(samplingMethod: String? = nil, positivePrompt: String = "", negativePrompt: String = "", width: Double = 512, height: Double = 512, cfgScale: Double = 7, samplingSteps: Double = 20, seed: String = "-1", batchCount: Double = 1, batchSize: Double = 1, clipSkip: Double = 1, selectedModel: StoredCheckpointModel? = nil, vaeModel: StoredVaeModel? = nil) {
    self.samplingMethod = samplingMethod
    self.positivePrompt = positivePrompt
    self.negativePrompt = negativePrompt
    self.width = width
    self.height = height
    self.cfgScale = cfgScale
    self.samplingSteps = samplingSteps
    self.seed = seed
    self.batchCount = batchCount
    self.batchSize = batchSize
    self.clipSkip = clipSkip
    self.selectedModel = selectedModel
    self.vaeModel = vaeModel
  }
}

extension StoredPromptModel {
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
    
    if let vaeModel = vaeModel {
      promptMetadata += "VAE: \(vaeModel.name)\n"
    }
    
    return promptMetadata
  }
}

extension MapModelData {
  
  @MainActor 
  func toStoredPromptModel(from promptModel: PromptModel) -> StoredPromptModel? {
    let storedCheckpointModel = toStoredCheckpointModel(from: promptModel.selectedModel)
    let storedVaeModel = toStoredVaeModel(from: promptModel.vaeModel)
    return StoredPromptModel(
                          samplingMethod: promptModel.samplingMethod,
                          positivePrompt: promptModel.positivePrompt,
                          negativePrompt: promptModel.negativePrompt,
                          width: promptModel.width,
                          height: promptModel.height,
                          cfgScale: promptModel.cfgScale,
                          samplingSteps: promptModel.samplingSteps,
                          seed: promptModel.seed,
                          batchCount: promptModel.batchCount,
                          batchSize: promptModel.batchSize,
                          clipSkip: promptModel.clipSkip,
                          selectedModel: storedCheckpointModel,
                          vaeModel: storedVaeModel
    )
  }
  
  @MainActor 
  func toPromptModel(from storedPromptModel: StoredPromptModel) -> PromptModel {
    let promptModel = PromptModel()
    promptModel.samplingMethod = storedPromptModel.samplingMethod
    promptModel.positivePrompt = storedPromptModel.positivePrompt
    promptModel.negativePrompt = storedPromptModel.negativePrompt
    promptModel.width = storedPromptModel.width
    promptModel.height = storedPromptModel.height
    promptModel.cfgScale = storedPromptModel.cfgScale
    promptModel.samplingSteps = storedPromptModel.samplingSteps
    promptModel.seed = storedPromptModel.seed
    promptModel.batchCount = storedPromptModel.batchCount
    promptModel.batchSize = storedPromptModel.batchSize
    promptModel.clipSkip = storedPromptModel.clipSkip
    promptModel.selectedModel = toCheckpointModel(from: storedPromptModel.selectedModel)
    promptModel.vaeModel = toVaeModel(from: storedPromptModel.vaeModel)
    return promptModel
  }
  
}
