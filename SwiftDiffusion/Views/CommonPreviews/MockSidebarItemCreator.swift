//
//  MockSidebarItemCreator.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import Foundation

class MockSidebarItemCreator {
  let sidebarModel: SidebarModel
  
  init(model: SidebarModel) {
    self.sidebarModel = model
  }
  
  @MainActor
  func createAndAddSidebarItem(
    title: String,
    checkpointName: String,
    checkpointPath: String = "path/to/models",
    checkpointType: StoredCheckpointModelType = .python,
    positivePrompt: String = "some, positive, prompt",
    thumbnailPath: String,
    thumbnailWidth: Int,
    thumbnailHeight: Int
  ) {
    let checkpoint = StoredCheckpointModel(name: checkpointName, path: checkpointPath, type: checkpointType)
    let prompt = StoredPromptModel()
    prompt.positivePrompt = positivePrompt
    prompt.selectedModel = checkpoint
    
    let item = SidebarItem(title: title, imageUrls: [])
    item.set(prompt: prompt)
    
    let thumbnailURL = URL(fileURLWithPath: thumbnailPath)
    let imageInfo = ImageInfo(url: thumbnailURL, width: CGFloat(thumbnailWidth), height: CGFloat(thumbnailHeight))
    item.imageThumbnails = [imageInfo]
    item.imagePreviews = [imageInfo]
    
    self.sidebarModel.rootFolder.add(item: item)
  }
}
