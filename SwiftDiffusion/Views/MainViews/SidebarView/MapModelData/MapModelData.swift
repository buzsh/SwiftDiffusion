//
//  MapModelData.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation

struct MapModelData {
  @MainActor
  func toStored(promptModel: PromptModel) -> StoredPromptModel? {
    return mapPromptModelToStoredPromptModel(promptModel)
  }
  
  @MainActor
  func fromStored(storedPromptModel: StoredPromptModel) -> PromptModel {
    return mapStoredPromptModelToPromptModel(storedPromptModel)
  }
  
  func mapCheckpointModelTypeToStoredCheckpointModelType(_ type: CheckpointModelType) -> StoredCheckpointModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
  func mapStoredCheckpointModelTypeToCheckpointModelType(_ type: StoredCheckpointModelType) -> CheckpointModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
  func mapJsonDataToCheckpointApiModel(title: String, modelName: String, hash: String? = nil, sha256: String? = nil, filename: String, config: String? = nil) -> CheckpointApiModel {
    return CheckpointApiModel(title: title,
                   modelName: modelName,
                   hash: hash,
                   sha256: sha256,
                   filename: filename,
                   config: config)
  }
  
  @MainActor
  func mapCheckpointModelToStoredCheckpointModel(_ checkpointModel: CheckpointModel?) -> StoredCheckpointModel? {
    guard let checkpointModel = checkpointModel else { return nil }
    let storedCheckpointModelType = mapCheckpointModelTypeToStoredCheckpointModelType(checkpointModel.type)
    return StoredCheckpointModel(name: checkpointModel.name,
                                 path: checkpointModel.path,
                                 type: storedCheckpointModelType,
                                 jsonModelCheckpointTitle: checkpointModel.checkpointApiModel?.title ?? "",
                                 jsonModelCheckpointName: checkpointModel.checkpointApiModel?.modelName ?? "",
                                 jsonModelCheckpointHash: checkpointModel.checkpointApiModel?.hash,
                                 jsonModelCheckpointSha256: checkpointModel.checkpointApiModel?.sha256,
                                 jsonModelCheckpointFilename: checkpointModel.checkpointApiModel?.filename ?? "",
                                 jsonModelCheckpointConfig: checkpointModel.checkpointApiModel?.config)
  }
  
  @MainActor
  func mapStoredCheckpointModelToCheckpointModel(_ storedCheckpointModel: StoredCheckpointModel?) -> CheckpointModel? {
    guard let storedCheckpointModel = storedCheckpointModel else { return nil }
    let checkpointModelType = mapStoredCheckpointModelTypeToCheckpointModelType(storedCheckpointModel.type)
    let checkpointApiModel = mapJsonDataToCheckpointApiModel(title: storedCheckpointModel.jsonModelCheckpointTitle, modelName: storedCheckpointModel.jsonModelCheckpointName, hash: storedCheckpointModel.jsonModelCheckpointHash, sha256: storedCheckpointModel.jsonModelCheckpointSha256, filename: storedCheckpointModel.jsonModelCheckpointFilename, config: storedCheckpointModel.jsonModelCheckpointConfig)
    
    return CheckpointModel(name: storedCheckpointModel.name,
                           path: storedCheckpointModel.path,
                           type: checkpointModelType,
                           checkpointApiModel: checkpointApiModel)
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
  func mapCheckpointMetadataToStoredSdModel(_ checkpointMetadata: CheckpointMetadata?) -> StoredCheckpointMetadata? {
    guard let checkpointMetadata = checkpointMetadata else { return nil }
    return StoredSdModel(title: checkpointMetadata.title,
                      modelName: checkpointMetadata.modelName,
                      hash: checkpointMetadata.hash,
                      sha256: checkpointMetadata.sha256,
                      filename: checkpointMetadata.filename,
                      config: checkpointMetadata.config)
  }
  
  func mapStoredCheckpointMetadataToCheckpointMetadataModel(_ storedCheckpointMetadata: StoredCheckpointMetadata?) -> CheckpointMetadata? {
    guard let storedCheckpointMetadata = storedCheckpointMetadata else { return nil }
    
    return SdModel(title: storedCheckpointMetadata.title,
                   modelName: storedCheckpointMetadata.modelName,
                   hash: storedCheckpointMetadata.hash,
                   sha256: storedCheckpointMetadata.sha256,
                   filename: storedCheckpointMetadata.filename,
                   config: storedCheckpointMetadata.config)
  }
  */
  
}
