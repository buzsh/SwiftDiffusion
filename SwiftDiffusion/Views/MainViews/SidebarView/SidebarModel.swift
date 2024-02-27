//
//  SidebarModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation
import SwiftData

@Model
class SidebarFolder {
  @Attribute var name: String
  @Relationship var contents: [SidebarItem]
  
  init(name: String, contents: [SidebarItem] = []) {
    self.name = name
    self.contents = contents
  }
}

extension SidebarFolder: Equatable {
  static func == (lhs: SidebarFolder, rhs: SidebarFolder) -> Bool {
    lhs.name == rhs.name
  }
}

@Model
class ImageInfo: Identifiable {
  @Attribute var id: UUID = UUID()
  @Attribute var url: URL
  @Attribute var width: CGFloat
  @Attribute var height: CGFloat
  
  init(url: URL, width: CGFloat, height: CGFloat) {
    self.url = url
    self.width = width
    self.height = height
  }
}


@Model
class SidebarItem: Identifiable {
  @Attribute var id: UUID = UUID()
  @Attribute var title: String
  @Attribute var timestamp: Date
  @Attribute var imageUrls: [URL] // Consider if this is still necessary or should be replaced entirely by ImageInfos
  @Relationship var imageThumbnails: [ImageInfo]
  @Relationship var imagePreviews: [ImageInfo]
  @Attribute var isWorkspaceItem: Bool = true
  @Relationship var prompt: StoredPromptModel?
  
  // Assuming your framework doesn't automatically handle relationship instantiation,
  // you might need to manually initialize these or ensure they're set post-initialization.
  init(title: String, timestamp: Date = Date(), imageUrls: [URL], isWorkspaceItem: Bool, prompt: StoredPromptModel? = nil) {
    self.title = title
    self.timestamp = timestamp
    self.imageUrls = imageUrls
    self.imageThumbnails = []
    self.imagePreviews = []
    self.isWorkspaceItem = isWorkspaceItem
    self.prompt = prompt
  }
}

extension SidebarItem: Equatable {
  static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
    lhs.id == rhs.id
  }
}

@Model
class StoredPromptModel {
  @Attribute var isWorkspaceItem: Bool
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
  @Relationship var selectedModel: StoredCheckpointModel?
  @Relationship var vaeModel: StoredVaeModel?

  init(isWorkspaceItem: Bool, samplingMethod: String? = nil, positivePrompt: String = "", negativePrompt: String = "", width: Double = 512, height: Double = 512, cfgScale: Double = 7, samplingSteps: Double = 20, seed: String = "-1", batchCount: Double = 1, batchSize: Double = 1, clipSkip: Double = 1, selectedModel: StoredCheckpointModel? = nil, vaeModel: StoredVaeModel? = nil) {
    self.isWorkspaceItem = isWorkspaceItem
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
    self.vaeModel = vaeModel
  }
}

@Model
class StoredCheckpointModel {
  @Attribute var name: String
  @Attribute var path: String
  @Attribute var type: StoredCheckpointModelType
  @Attribute var storedCheckpointApiModel: StoredCheckpointApiModel?
  
  init(name: String, path: String, type: StoredCheckpointModelType, storedCheckpointApiModel: StoredCheckpointApiModel? = nil) {
    self.name = name
    self.path = path
    self.type = type
    self.storedCheckpointApiModel = storedCheckpointApiModel
  }
}

enum StoredCheckpointModelType: String, Codable {
  case coreMl = "coreMl"
  case python = "python"
}

@Model
class StoredCheckpointApiModel {
  @Attribute var title: String
  @Attribute var modelName: String
  @Attribute var modelHash: String?
  @Attribute var sha256: String?
  @Attribute var filename: String
  @Attribute var config: String?
  
  init(title: String, modelName: String, modelHash: String? = nil, sha256: String? = nil, filename: String, config: String? = nil) {
    self.title = title
    self.modelName = modelName
    self.modelHash = modelHash
    self.sha256 = sha256
    self.filename = filename
    self.config = config
  }
}

// MARK: Additional Settings
@Model
class StoredVaeModel {
  @Attribute var name: String
  @Attribute var path: String
  
  init(name: String, path: String) {
    self.name = name
    self.path = path
  }
}
