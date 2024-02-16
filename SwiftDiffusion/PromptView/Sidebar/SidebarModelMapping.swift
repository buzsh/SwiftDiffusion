//
//  SidebarModelMapping.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation

struct ModelDataMapping {
  @MainActor
  func toArchive(promptModel: PromptModel) -> AppPromptModel? {
    return mapPromptModelToAppPromptModel(promptModel)
  }
  
  @MainActor
  func fromArchive(appPromptModel: AppPromptModel) -> PromptModel {
    return mapAppPromptModelToPromptModel(appPromptModel)
  }
  
  func mapModelTypeToAppModelType(_ type: ModelType) -> AppModelType {
    switch type {
    case .coreMl:
      return .coreMl
    case .python:
      return .python
    }
  }
  
  func mapAppModelTypeToModelType(_ type: AppModelType) -> ModelType {
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
  func mapModelItemToAppModelItem(_ modelItem: ModelItem?) -> AppModelItem? {
    guard let modelItem = modelItem else { return nil }
    let appModelType = mapModelTypeToAppModelType(modelItem.type)
    return AppModelItem(name: modelItem.name,
                        type: appModelType,
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
  func mapAppModelItemToModelItem(_ appModelItem: AppModelItem?) -> ModelItem? {
    guard let appModelItem = appModelItem else { return nil }
    let modelType = mapAppModelTypeToModelType(appModelItem.type)
    let sdModel = mapJsonDataToSdModel(title: appModelItem.jsonModelCheckpointTitle, modelName: appModelItem.jsonModelCheckpointName, hash: appModelItem.jsonModelCheckpointHash, sha256: appModelItem.jsonModelCheckpointSha256, filename: appModelItem.jsonModelCheckpointFilename, config: appModelItem.jsonModelCheckpointConfig)
    
    return ModelItem(name: appModelItem.name,
                     type: modelType,
                     url: appModelItem.url,
                     isDefaultModel: appModelItem.isDefaultModel,
                     sdModel: sdModel)
  }
  
  
  
  @MainActor
  func mapPromptModelToAppPromptModel(_ promptModel: PromptModel) -> AppPromptModel? {
    guard let selectedModel = mapModelItemToAppModelItem(promptModel.selectedModel) else { return nil }
    return AppPromptModel(isWorkspaceItem: promptModel.isWorkspaceItem, // workspace item flag
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
  func mapAppPromptModelToPromptModel(_ appPromptModel: AppPromptModel) -> PromptModel {
    let promptModel = PromptModel()
    promptModel.isWorkspaceItem = appPromptModel.isWorkspaceItem
    promptModel.isArchived = appPromptModel.isArchived
    promptModel.samplingMethod = appPromptModel.samplingMethod
    promptModel.positivePrompt = appPromptModel.positivePrompt
    promptModel.negativePrompt = appPromptModel.negativePrompt
    promptModel.width = appPromptModel.width
    promptModel.height = appPromptModel.height
    promptModel.cfgScale = appPromptModel.cfgScale
    promptModel.samplingSteps = appPromptModel.samplingSteps
    promptModel.seed = appPromptModel.seed
    promptModel.batchCount = appPromptModel.batchCount
    promptModel.batchSize = appPromptModel.batchSize
    promptModel.clipSkip = appPromptModel.clipSkip
    
    if let appModelItem = appPromptModel.selectedModel {
      promptModel.selectedModel = mapAppModelItemToModelItem(appModelItem)
    } else {
      promptModel.selectedModel = nil
    }
    
    return promptModel
  }
  /*
  func mapSdModelToAppSdModel(_ sdModel: SdModel?) -> AppSdModel? {
    guard let sdModel = sdModel else { return nil }
    return AppSdModel(title: sdModel.title,
                      modelName: sdModel.modelName,
                      hash: sdModel.hash,
                      sha256: sdModel.sha256,
                      filename: sdModel.filename,
                      config: sdModel.config)
  }
  
  func mapAppSdModelToSdModel(_ appSdModel: AppSdModel?) -> SdModel? {
    guard let appSdModel = appSdModel else { return nil }
    
    return SdModel(title: appSdModel.title,
                   modelName: appSdModel.modelName,
                   hash: appSdModel.hash,
                   sha256: appSdModel.sha256,
                   filename: appSdModel.filename,
                   config: appSdModel.config)
  }
  */
  
}
