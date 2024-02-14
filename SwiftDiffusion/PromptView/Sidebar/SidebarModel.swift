//
//  SidebarModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation
import SwiftData

@Model
class SidebarItem: Identifiable {
  @Attribute var id: UUID = UUID()
  @Attribute var title: String
  @Attribute var timestamp: Date
  @Attribute var imageUrls: [URL]
  @Relationship var prompt: AppPromptModel?
  
  init(title: String, timestamp: Date = Date(), imageUrls: [URL], prompt: AppPromptModel? = nil) {
    self.title = title
    self.timestamp = timestamp
    self.imageUrls = imageUrls
    self.prompt = prompt
  }
}

@Model
class AppPromptModel {
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
  @Relationship var selectedModel: AppModelItem?
  
  init(positivePrompt: String = "", negativePrompt: String = "", width: Double = 512, height: Double = 512, cfgScale: Double = 7, samplingSteps: Double = 20, seed: String = "-1", batchCount: Double = 1, batchSize: Double = 1, clipSkip: Double = 1, selectedModel: AppModelItem? = nil) {
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
class AppModelItem {
  @Attribute var name: String
  @Attribute var type: AppModelType
  @Attribute var url: URL
  @Attribute var isDefaultModel: Bool = false
  @Relationship var sdModel: AppSdModel?
  
  init(name: String, type: AppModelType, url: URL, isDefaultModel: Bool = false, sdModel: AppSdModel? = nil) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    self.sdModel = sdModel
  }
}

func mapModelTypeToAppModelType(_ type: ModelType?) -> AppModelType? {
  guard let type = type else { return nil }
  switch type {
  case .coreMl:
    return .coreMl
  case .python:
    return .python
  }
}

enum AppModelType: String, Codable {
  case coreMl = "coreMl"
  case python = "python"
}

@Model
class AppSdModel {
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

@Model
class SidebarFolder {
  @Attribute var name: String
  @Relationship var contents: [SidebarItem]
  
  init(name: String, contents: [SidebarItem] = []) {
    self.name = name
    self.contents = contents
  }
}

/*
 struct SidebarView: View {
 @Query var folders: [SidebarFolder] // Use the Query property wrapper to fetch folders
 
 var body: some View {
 List(folders, children: \.contents) { item in
 // Representation of SidebarItem or SidebarFolder
 Text(item.name) // Adjust based on your item or folder properties
 }
 }
 }
 */
