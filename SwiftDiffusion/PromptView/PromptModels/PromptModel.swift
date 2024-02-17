//
//  PromptModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Combine

@MainActor
class PromptModel: ObservableObject {
  @Published var isWorkspaceItem: Bool = true
  
  @Published var selectedModel: ModelItem?
  
  //@Published var selectedCoreMlCheckpointModel: CoreMlCheckpointModel?
  @Published var selectedPythonCheckpointModel: PythonCheckpointModel?
  
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
}

extension PromptModel {
  func updateProperties(from model: PromptModel) {
    Debug.log("updateProperties from\n        selectedModel: \(String(describing: selectedModel?.name))")
    Debug.log("        sdModel.title: \(String(describing: selectedModel?.sdModel?.title))")
    
    self.isWorkspaceItem = model.isWorkspaceItem
    
    self.selectedModel = model.selectedModel
    
    //self.selectedCoreMlCheckpointModel = model.selectedCoreMlCheckpointModel
    self.selectedPythonCheckpointModel = model.selectedPythonCheckpointModel
    
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
    
    return promptMetadata
  }
}



/*
 @Published var selectedModel: ModelItem? {
 didSet {
 updatePromptPreferences()
 }
 }
 
 private func updatePromptPreferences() {
 guard let model = selectedModel else { return }
 samplingMethod = model.preferences.samplingMethod
 // Update only if the current values are the default (512x512)
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
 */
