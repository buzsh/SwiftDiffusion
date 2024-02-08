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
  @Published var preferences: ModelPreferences
  
  init(name: String, type: ModelType, url: URL, isDefaultModel: Bool = false) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    self.preferences = ModelPreferences.defaultForModelType(type: type)
  }
}

enum ModelType {
  case coreMl
  case python
}

struct ModelPreferences {
  var samplingMethod: String
  var positivePrompt: String = ""
  var negativePrompt: String = ""
  var width: Double = 512
  var height: Double = 512
  var cfgScale: Double = 7
  var samplingSteps: Double = 20
  var clipSkip: Double = 1
  var batchCount: Double = 1
  var batchSize: Double = 1
  var seed: String = "-1"
  
  static func defaultForModelType(type: ModelType) -> ModelPreferences {
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
