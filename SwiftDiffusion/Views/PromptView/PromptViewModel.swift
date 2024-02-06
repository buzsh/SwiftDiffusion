//
//  PromptViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Combine

class PromptViewModel: ObservableObject {
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
}
