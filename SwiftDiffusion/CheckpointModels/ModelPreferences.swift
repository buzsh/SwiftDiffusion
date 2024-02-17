//
//  ModelPreferences.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

@MainActor
class ModelPreferences: ObservableObject {
  @Published var samplingMethod: String
  @Published var positivePrompt: String = ""
  @Published var negativePrompt: String = ""
  @Published var width: Double = 512
  @Published var height: Double = 512
  @Published var cfgScale: Double = 7
  @Published var samplingSteps: Double = 20
  @Published var clipSkip: Double = 1
  @Published var batchCount: Double = 1
  @Published var batchSize: Double = 1
  @Published var seed: String = "-1"
  
  init(samplingMethod: String = "DPM++ 2M Karras") {
    self.samplingMethod = samplingMethod
  }
  
  static func defaultSamplingForModelType(type: ModelType) -> ModelPreferences {
    let samplingMethod: String
    switch type {
    case .coreMl:
      samplingMethod = "DPM-Solver++"
    case .python:
      samplingMethod = "DPM++ 2M Karras"
    }
    return ModelPreferences(samplingMethod: samplingMethod)
  }
}

extension ModelPreferences {
  convenience init(from promptModel: PromptModel) {
    self.init(samplingMethod: promptModel.samplingMethod ?? "DPM++ 2M Karras")
    self.positivePrompt = promptModel.positivePrompt
    self.negativePrompt = promptModel.negativePrompt
    self.width = promptModel.width
    self.height = promptModel.height
    self.cfgScale = promptModel.cfgScale
    self.samplingSteps = promptModel.samplingSteps
    self.clipSkip = promptModel.clipSkip
    self.batchCount = promptModel.batchCount
    self.batchSize = promptModel.batchSize
    self.seed = promptModel.seed
  }
}
