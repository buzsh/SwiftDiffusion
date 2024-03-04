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
  @Relationship var parent: SidebarItem
  //@Relationship(deleteRule: .cascade, inverse: \StoredPromptModel.parent) var selectedModel: StoredCheckpointModel
  @Relationship var selectedModel: StoredCheckpointModel?
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
  @Relationship var vaeModel: StoredVaeModel?

  init(parent: SidebarItem, selectedModel: StoredCheckpointModel? = nil, samplingMethod: String? = nil, positivePrompt: String = "", negativePrompt: String = "", width: Double = 512, height: Double = 512, cfgScale: Double = 7, samplingSteps: Double = 20, seed: String = "-1", batchCount: Double = 1, batchSize: Double = 1, clipSkip: Double = 1, vaeModel: StoredVaeModel? = nil) {
    self.parent = parent
    // TODO: Rename "modelCheckpoint"
    self.selectedModel = selectedModel
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
    self.vaeModel = vaeModel
  }
}
