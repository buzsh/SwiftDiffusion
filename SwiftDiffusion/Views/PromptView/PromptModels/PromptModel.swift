//
//  PromptModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Combine

@MainActor
class PromptModel: ObservableObject {
  @Published var selectedModel: ModelItem?
  /*
  @Published var selectedModel: ModelItem? {
    didSet {
      updatePromptPreferences()
    }
  }
   */
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
}
