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
    let appModelItem1 = AppModelItem(name: "DreamShaperXL_v2.0", type: .coreMl, url: URL(string: "https://example.com/model")!, isDefaultModel: true, jsonModelCheckpointTitle: "JSON Model Title", jsonModelCheckpointName: "JSON Model Name", jsonModelCheckpointFilename: "JSON Model Filename")
    let appPromptModel1 = AppPromptModel(positivePrompt: "A sunny day", negativePrompt: "A rainy day", selectedModel: appModelItem1)
    
    let appModelItem2 = AppModelItem(name: "Animerge 1.6.2", type: .coreMl, url: URL(string: "https://example.com/model")!, isDefaultModel: true, jsonModelCheckpointTitle: "JSON Model Title", jsonModelCheckpointName: "JSON Model Name", jsonModelCheckpointFilename: "JSON Model Filename")
    let appPromptModel2 = AppPromptModel(positivePrompt: "A sunny day", negativePrompt: "A rainy day", selectedModel: appModelItem2)
    
    let sidebarItem1 = SidebarItem(title: "Gloomy Days", imageUrls: mockImageUrls, prompt: appPromptModel1)
    let sidebarItem2 = SidebarItem(title: "Sunshine Overlook", imageUrls: mockImageUrls, prompt: appPromptModel2)
    
    let sidebarFolder1 = SidebarFolder(name: "Personal", contents: [sidebarItem1, sidebarItem2])
    let sidebarFolder2 = SidebarFolder(name: "Shared", contents: [sidebarItem1, sidebarItem2])
    
    context.insert(appModelItem1)
    context.insert(appModelItem2)
    context.insert(appPromptModel1)
    context.insert(appPromptModel2)
    context.insert(sidebarItem1)
    context.insert(sidebarItem2)
    context.insert(sidebarFolder1)
    context.insert(sidebarFolder2)
    
    do {
      try context.save()
    } catch {
      Debug.log("Failed to save mock data: \(error)")
    }
  }
}
