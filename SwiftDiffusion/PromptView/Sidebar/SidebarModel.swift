//
//  SidebarModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation
import SwiftData

extension SidebarFolder: Equatable {
  static func == (lhs: SidebarFolder, rhs: SidebarFolder) -> Bool {
    lhs.name == rhs.name
  }
}

@Model
class SidebarFolder {
  @Attribute var name: String
  @Relationship var contents: [SidebarItem]
  
  init(name: String, contents: [SidebarItem] = []) {
    self.name = name
    self.contents = contents
  }
}

extension SidebarItem: Equatable {
  static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
    lhs.id == rhs.id
  }
}

@Model
class SidebarItem: Identifiable {
  @Attribute var id: UUID = UUID()
  @Attribute var title: String
  @Attribute var timestamp: Date
  @Attribute var imageUrls: [URL]
  @Relationship var prompt: StoredPromptModel?
  
  init(title: String, timestamp: Date = Date(), imageUrls: [URL], prompt: StoredPromptModel? = nil) {
    self.title = title
    self.timestamp = timestamp
    self.imageUrls = imageUrls
    self.prompt = prompt
  }
}

@Model
class StoredPromptModel {
  @Attribute var isWorkspaceItem: Bool = false
  @Attribute var isArchived: Bool = true
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
  @Relationship var selectedModel: StoredModelItem?
  
  
  
  init(isWorkspaceItem: Bool = false, isArchived: Bool = true, samplingMethod: String? = nil, positivePrompt: String = "", negativePrompt: String = "", width: Double = 512, height: Double = 512, cfgScale: Double = 7, samplingSteps: Double = 20, seed: String = "-1", batchCount: Double = 1, batchSize: Double = 1, clipSkip: Double = 1, selectedModel: StoredModelItem? = nil) {
    self.isWorkspaceItem = isWorkspaceItem
    self.isArchived = isArchived
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
    self.selectedModel = selectedModel
  }
}

@Model
class StoredModelItem {
  @Attribute var name: String
  @Attribute var type: StoredModelType
  @Attribute var url: URL
  @Attribute var isDefaultModel: Bool = false
  
  @Attribute var jsonModelCheckpointTitle: String
  @Attribute var jsonModelCheckpointName: String
  @Attribute var jsonModelCheckpointHash: String?
  @Attribute var jsonModelCheckpointSha256: String?
  @Attribute var jsonModelCheckpointFilename: String
  @Attribute var jsonModelCheckpointConfig: String?
  
  init(name: String, type: StoredModelType, url: URL, isDefaultModel: Bool = false, jsonModelCheckpointTitle: String, jsonModelCheckpointName: String, jsonModelCheckpointHash: String? = nil, jsonModelCheckpointSha256: String? = nil, jsonModelCheckpointFilename: String, jsonModelCheckpointConfig: String? = nil) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    
    self.jsonModelCheckpointTitle = jsonModelCheckpointTitle
    self.jsonModelCheckpointName = jsonModelCheckpointName
    self.jsonModelCheckpointHash = jsonModelCheckpointHash
    self.jsonModelCheckpointSha256 = jsonModelCheckpointSha256
    self.jsonModelCheckpointFilename = jsonModelCheckpointFilename
    self.jsonModelCheckpointConfig = jsonModelCheckpointConfig
  }
}

func mapModelTypeToStoredModelType(_ type: ModelType?) -> StoredModelType? {
  guard let type = type else { return nil }
  switch type {
  case .coreMl:
    return .coreMl
  case .python:
    return .python
  }
}

enum StoredModelType: String, Codable {
  case coreMl = "coreMl"
  case python = "python"
}

/*
@Model
class StoredSdModel {
  @Attribute var title: String
  @Attribute var modelName: String
  @Attribute var hash: String?
  @Attribute var sha256: String?
  @Attribute var filename: String
  @Attribute var config: String?
  
  init(title: String, modelName: String, hash: String? = nil, sha256: String? = nil, filename: String, config: String? = nil) {
    self.title = title
    self.modelName = modelName
    self.hash = hash
    self.sha256 = sha256
    self.filename = filename
    self.config = config
  }
}
 */

