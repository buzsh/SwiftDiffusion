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
    case .coreMl:
      return .coreMl
    case .python:
      return .python
    }
  }
  
  func mapStoredModelTypeToModelType(_ type: StoredModelType) -> ModelType {
    switch type {
    case .coreMl:
      return .coreMl
    case .python:
      return .python
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
  func mapModelItemToStoredModelItem(_ modelItem: ModelItem?) -> StoredModelItem? {
    guard let modelItem = modelItem else { return nil }
    let storedModelType = mapModelTypeToStoredModelType(modelItem.type)
    return StoredModelItem(name: modelItem.name,
                        type: storedModelType,
                        url: modelItem.url,
                        isDefaultModel: modelItem.isDefaultModel,
                        jsonModelCheckpointTitle: modelItem.sdModel?.title ?? "",
                        jsonModelCheckpointName: modelItem.sdModel?.modelName ?? "",
                        jsonModelCheckpointHash: modelItem.sdModel?.hash,
                        jsonModelCheckpointSha256: modelItem.sdModel?.sha256,
                        jsonModelCheckpointFilename: modelItem.sdModel?.filename ?? "",
                        jsonModelCheckpointConfig: modelItem.sdModel?.config)
  }
  
  @MainActor
  func mapStoredModelItemToModelItem(_ storedModelItem: StoredModelItem?) -> ModelItem? {
    guard let storedModelItem = storedModelItem else { return nil }
    let modelType = mapStoredModelTypeToModelType(storedModelItem.type)
    let sdModel = mapJsonDataToSdModel(title: storedModelItem.jsonModelCheckpointTitle, modelName: storedModelItem.jsonModelCheckpointName, hash: storedModelItem.jsonModelCheckpointHash, sha256: storedModelItem.jsonModelCheckpointSha256, filename: storedModelItem.jsonModelCheckpointFilename, config: storedModelItem.jsonModelCheckpointConfig)
    
    return ModelItem(name: storedModelItem.name,
                     type: modelType,
                     url: storedModelItem.url,
                     isDefaultModel: storedModelItem.isDefaultModel,
                     sdModel: sdModel)
  }
  
  
  
  @MainActor
  func mapPromptModelToStoredPromptModel(_ promptModel: PromptModel) -> StoredPromptModel? {
    guard let selectedModel = mapModelItemToStoredModelItem(promptModel.selectedModel) else { return nil }
    return StoredPromptModel(isWorkspaceItem: promptModel.isWorkspaceItem, // workspace item flag
                          isArchived: true,                             // archive flag
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
    promptModel.isWorkspaceItem = storedPromptModel.isWorkspaceItem
    promptModel.isArchived = storedPromptModel.isArchived
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
    
    if let storedModelItem = storedPromptModel.selectedModel {
      promptModel.selectedModel = mapStoredModelItemToModelItem(storedModelItem)
    } else {
      promptModel.selectedModel = nil
    }
    
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
