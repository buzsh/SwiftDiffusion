//
//  SidebarMockDataController.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/14/24.
//

import SwiftData
import SwiftUI

@MainActor
class MockDataController {
  static let shared = MockDataController()
  
  let container: ModelContainer
  
  var mockImageUrls: [URL] = [
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1a.png")!,
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1b.png")!,
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1c.png")!,
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1-grid.png")!
  ]
  
  var lastImage: NSImage? {
    guard let lastUrl = mockImageUrls.last else { return nil }
    return NSImage(contentsOf: lastUrl)
  }
  
  init() {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
      container = try ModelContainer(for: SidebarItem.self, AppPromptModel.self, AppModelItem.self, SidebarFolder.self, configurations: config)
      insertMockData()
    } catch {
      fatalError("Failed to initialize the mock ModelContainer: \(error)")
    }
  }
  
  func insertMockData() {
    let context = container.mainContext
    
    let appModelItem = AppModelItem(name: "Example Model", type: .coreMl, url: URL(string: "https://example.com/model")!, isDefaultModel: true, jsonModelCheckpointTitle: "JSON Model Title", jsonModelCheckpointName: "JSON Model Name", jsonModelCheckpointFilename: "JSON Model Filename")

    //let appSdModel = AppSdModel(title: "SD Model", modelName: "Example SD Model", filename: "example.sdmodel")
    //appModelItem.sdModel = appSdModel
    
    let appPromptModel = AppPromptModel(positivePrompt: "A sunny day", negativePrompt: "A rainy day", selectedModel: appModelItem)
    
    let sidebarItem = SidebarItem(title: "Item 1", imageUrls: mockImageUrls, prompt: appPromptModel)
    
    let sidebarFolder = SidebarFolder(name: "Folder 1", contents: [sidebarItem])
    
    context.insert(appModelItem)
    //context.insert(appSdModel)
    context.insert(appPromptModel)
    context.insert(sidebarItem)
    context.insert(sidebarFolder)
    
    do {
      try context.save()
    } catch {
      Debug.log("Failed to save mock data: \(error)")
    }
  }
}
