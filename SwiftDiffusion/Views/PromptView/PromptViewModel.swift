//
//  PromptViewModel.swift
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

class PromptViewModel: ObservableObject {
  @Published var selectedModel: ModelItem?
  @Published var samplingMethod: String?
  
  @Published var positivePrompt: String = ""
  @Published var negativePrompt: String = ""
  
  // make sure to export as int
  @Published var width: Double = 512  // 64 - 2048
  @Published var height: Double = 512 // 768
  
  @Published var cfgScale: Double = 7 // 1 - 30
  @Published var samplingSteps: Double = 20 // 1 - 150
  
  // convert back to int
  @Published var seed: String = "-1"
  
  @Published var batchCount: Double = 1  // 1 - 100
  @Published var batchSize: Double = 1 // 1 - 8
  
  @Published var clipSkip: Double = 1 // 1 - 12
  
  // CoreML Sampling Methods:
  // ['DPM-Solver++', 'PLMS']
  
  // Python Sampling Methods:
  // ['DPM++ 2M Karras', 'DPM++ SDE Karras', 'DPM++ 2M SDE Exponential', 'DPM++ 2M SDE Karras', 'Euler a', 'Euler', 'LMS', 'Heun', 'DPM2', 'DPM2 a', 'DPM++ 2S a', 'DPM++ 2M', 'DPM++ SDE', 'DPM++ 2M SDE', 'DPM++ 2M SDE Heun', 'DPM++ 2M SDE Heun Karras', 'DPM++ 2M SDE Heun Exponential', 'DPM++ 3M SDE', 'DPM++ 3M SDE Karras', 'DPM++ 3M SDE Exponential', 'DPM fast', 'DPM adaptive', 'LMS Karras', 'DPM2 Karras', 'DPM2 a Karras', 'DPM++ 2S a Karras', 'Restart', 'DDIM', 'PLMS', 'UniPC', 'LCM']
}
