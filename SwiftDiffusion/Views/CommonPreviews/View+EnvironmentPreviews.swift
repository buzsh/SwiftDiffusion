//
//  View+EnvironmentPreviews.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI
import SwiftData

extension View {
  @MainActor func configuredPreview() -> some View {
    let modelContainer: ModelContainer
    do {
      modelContainer = try ModelContainer(for: SidebarFolder.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    } catch {
      fatalError("Failed to initialize model container for previews: \(error)")
    }
    modelContainer.mainContext.autosaveEnabled = true
    let sidebarModelPreview = SidebarModel(modelContext: modelContainer.mainContext)
    let updateManagerPreview = UpdateManager()
    let promptModelPreview = PromptModel()
    let checkpointsManagerPreview = CheckpointsManager()
    let loraModelsManagerPreview = ModelManager<LoraModel>()
    let vaeModelsManagerPreview = ModelManager<VaeModel>()
    
    insertMockData(for: sidebarModelPreview, into: modelContainer)
    
    return self
      .environmentObject(sidebarModelPreview)
      .environmentObject(promptModelPreview)
      .environmentObject(checkpointsManagerPreview)
      .environmentObject(loraModelsManagerPreview)
      .environmentObject(vaeModelsManagerPreview)
      .environmentObject(updateManagerPreview)
  }
  
  @MainActor
  private func insertMockData(for sidebarModel: SidebarModel, into modelContainer: ModelContainer) {
    let context = modelContainer.mainContext
    
    let workspacePrompt = StoredPromptModel()
    workspacePrompt.positivePrompt = "some, sample, workspace, prompt, data, positive, title, preview"
    sidebarModel.createNewWorkspaceItem(withPrompt: workspacePrompt)
    
    let rootFolderItems = [
      SidebarFolder(name: "Portfolio"),
      SidebarFolder(name: "Study")
    ]
    
    for folder in rootFolderItems {
      sidebarModel.rootFolder.add(folder: folder)
    }
    
    let itemCreator = MockSidebarItemCreator(model: sidebarModel)
    
    itemCreator.createCustomSidebarItem(
      title: "jelly, prompt, data, positive, title, preview",
      checkpointName: "juggernautXL_v9Rdphoto2Lightning.safetensors",
      baseAssetName: "pastel",
      thumbnailWidth: 666,
      thumbnailHeight: 1000
    )
    
    itemCreator.createCustomSidebarItem(
      title: "jelly, prompt, data, positive, title, preview",
      checkpointName: "juggernautXL_v9Rdphoto2Lightning.safetensors",
      baseAssetName: "jelly",
      thumbnailWidth: 666,
      thumbnailHeight: 1000
    )
    
    itemCreator.createCustomSidebarItem(
      title: "jelly, prompt, data, positive, title, preview",
      checkpointName: "juggernautXL_v9Rdphoto2Lightning.safetensors",
      baseAssetName: "boat",
      thumbnailWidth: 666,
      thumbnailHeight: 1000
    )
    
    do {
      try context.save()
    } catch {
      fatalError("Failed to save mock data to the model context: \(error)")
    }
  }
  
}

#Preview("Sidebar") {
  CommonPreviews.sidebar
    .frame(width: 300, height: 600)
}
