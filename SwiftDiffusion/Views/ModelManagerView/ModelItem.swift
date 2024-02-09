//
//  ModelItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation
import Combine

@MainActor
class ModelItem: ObservableObject, Identifiable {
  let id = UUID()
  let name: String
  let type: ModelType
  let url: URL
  
  var isDefaultModel: Bool = false
  
  var sdModelCheckpoint: String?
  
  @Published var preferences: ModelPreferences
  
  init(name: String, type: ModelType, url: URL, isDefaultModel: Bool = false) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    self.preferences = ModelPreferences.defaultSamplingForModelType(type: type)
  }
  
  func setSdModelCheckpoint(_ checkpoint: String) {
    self.sdModelCheckpoint = checkpoint
  }
}

enum ModelType {
  case coreMl
  case python
}

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
  convenience init(from promptViewModel: PromptViewModel) {
    self.init(samplingMethod: promptViewModel.samplingMethod ?? "DPM++ 2M Karras") // Provide a default or handle nil differently
    self.positivePrompt = promptViewModel.positivePrompt
    self.negativePrompt = promptViewModel.negativePrompt
    self.width = promptViewModel.width
    self.height = promptViewModel.height
    self.cfgScale = promptViewModel.cfgScale
    self.samplingSteps = promptViewModel.samplingSteps
    self.clipSkip = promptViewModel.clipSkip
    self.batchCount = promptViewModel.batchCount
    self.batchSize = promptViewModel.batchSize
    self.seed = promptViewModel.seed
  }
}
