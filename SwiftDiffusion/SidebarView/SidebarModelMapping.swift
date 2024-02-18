//
//  SidebarModelMstoreding.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation

struct MapModelData {
  @MainActor
  func toArchive(promptModel: PromptModel) -> StoredPromptModel? {
    return mapPromptModelToStoredPromptModel(promptModel)
  }
  
  @MainActor
  func fromArchive(storedPromptModel: StoredPromptModel) -> PromptModel {
    return mapStoredPromptModelToPromptModel(storedPromptModel)
  }
  
  func mapModelTypeToStoredModelType(_ type: ModelType) -> StoredModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
  func mapStoredModelTypeToModelType(_ type: StoredModelType) -> ModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
  func mapJsonDataToSdModel(title: String, modelName: String, hash: String? = nil, sha256: String? = nil, filename: String, config: String? = nil) -> SdModel {
    return SdModel(title: title,
                   modelName: modelName,
                   hash: hash,
                   sha256: sha256,
                   filename: filename,
                   config: config)
  }
  
  @MainActor
  func mapCheckpointModelToStoredCheckpointModel(_ checkpointModel: CheckpointModel?) -> StoredCheckpointModel? {
    guard let checkpointModel = checkpointModel else { return nil }
    let storedModelType = mapModelTypeToStoredModelType(checkpointModel.type)
    return StoredCheckpointModel(name: checkpointModel.name,
                        type: storedModelType,
                        url: checkpointModel.url,
                        isDefaultModel: checkpointModel.isDefaultModel,
                        jsonModelCheckpointTitle: checkpointModel.sdModel?.title ?? "",
                        jsonModelCheckpointName: checkpointModel.sdModel?.modelName ?? "",
                        jsonModelCheckpointHash: checkpointModel.sdModel?.hash,
                        jsonModelCheckpointSha256: checkpointModel.sdModel?.sha256,
                        jsonModelCheckpointFilename: checkpointModel.sdModel?.filename ?? "",
                        jsonModelCheckpointConfig: checkpointModel.sdModel?.config)
  }
  
  @MainActor
  func mapStoredCheckpointModelToCheckpointModel(_ storedCheckpointModel: StoredCheckpointModel?) -> CheckpointModel? {
    guard let storedCheckpointModel = storedCheckpointModel else { return nil }
    let modelType = mapStoredModelTypeToModelType(storedCheckpointModel.type)
    let sdModel = mapJsonDataToSdModel(title: storedCheckpointModel.jsonModelCheckpointTitle, modelName: storedCheckpointModel.jsonModelCheckpointName, hash: storedCheckpointModel.jsonModelCheckpointHash, sha256: storedCheckpointModel.jsonModelCheckpointSha256, filename: storedCheckpointModel.jsonModelCheckpointFilename, config: storedCheckpointModel.jsonModelCheckpointConfig)
    
    return CheckpointModel(name: storedCheckpointModel.name,
                     type: modelType,
                     url: storedCheckpointModel.url,
                     isDefaultModel: storedCheckpointModel.isDefaultModel,
                     sdModel: sdModel)
  }
  
  
  
  @MainActor
  func mapPromptModelToStoredPromptModel(_ promptModel: PromptModel) -> StoredPromptModel? {
    var selectedModel: StoredCheckpointModel?
    selectedModel = mapCheckpointModelToStoredCheckpointModel(promptModel.selectedModel)
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
                          selectedModel: selectedModel)
  }
  
  @MainActor
  func mapStoredPromptModelToPromptModel(_ storedPromptModel: StoredPromptModel) -> PromptModel {
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
    promptModel.selectedModel = mapStoredCheckpointModelToCheckpointModel(storedPromptModel.selectedModel)
    return promptModel
  }
  /*
  func mapSdModelToStoredSdModel(_ sdModel: SdModel?) -> StoredSdModel? {
    guard let sdModel = sdModel else { return nil }
    return StoredSdModel(title: sdModel.title,
                      modelName: sdModel.modelName,
                      hash: sdModel.hash,
                      sha256: sdModel.sha256,
                      filename: sdModel.filename,
                      config: sdModel.config)
  }
  
  func mapStoredSdModelToSdModel(_ storedSdModel: StoredSdModel?) -> SdModel? {
    guard let storedSdModel = storedSdModel else { return nil }
    
    return SdModel(title: storedSdModel.title,
                   modelName: storedSdModel.modelName,
                   hash: storedSdModel.hash,
                   sha256: storedSdModel.sha256,
                   filename: storedSdModel.filename,
                   config: storedSdModel.config)
  }
  */
  
}
