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
  
  @MainActor
  func mapModelItemToAppModelItem(_ modelItem: ModelItem?) -> AppModelItem? {
    guard let modelItem = modelItem else { return nil }
    let appModelType = mapModelTypeToAppModelType(modelItem.type)
    return AppModelItem(name: modelItem.name,
                        type: appModelType,
                        url: modelItem.url,
                        isDefaultModel: modelItem.isDefaultModel,
                        sdModel: nil)
  }
  
  @MainActor
  func mapAppModelItemToModelItem(_ appModelItem: AppModelItem) -> ModelItem {
    let modelType = mapAppModelTypeToModelType(appModelItem.type)
    let modelItem = ModelItem(name: appModelItem.name,
                              type: modelType,
                              url: appModelItem.url,
                              isDefaultModel: appModelItem.isDefaultModel)
    return modelItem
  }
  
  
  @MainActor
  func mapPromptModelToAppPromptModel(_ promptModel: PromptModel) -> AppPromptModel? {
    guard let selectedModel = mapModelItemToAppModelItem(promptModel.selectedModel) else { return nil }
    return AppPromptModel(positivePrompt: promptModel.positivePrompt,
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
  
  func mapSdModelToAppSdModel(_ sdModel: SdModel) -> AppSdModel {
    return AppSdModel(title: sdModel.title,
                      modelName: sdModel.modelName,
                      hash: sdModel.hash,
                      sha256: sdModel.sha256,
                      filename: sdModel.filename,
                      config: sdModel.config)
  }
  
  func mapAppSdModelToSdModel(_ appSdModel: AppSdModel) -> SdModel {
    return SdModel(title: appSdModel.title,
                   modelName: appSdModel.modelName,
                   hash: appSdModel.hash,
                   sha256: appSdModel.sha256,
                   filename: appSdModel.filename,
                   config: appSdModel.config)
  }
  
}
