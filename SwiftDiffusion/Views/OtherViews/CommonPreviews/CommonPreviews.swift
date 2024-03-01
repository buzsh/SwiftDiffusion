//
//  CommonPreviews.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct CommonPreviews {
  
  @MainActor
  static var previewEnvironment: some View {
    let promptModelPreview = PromptModel()
    let checkpointsManagerPreview = CheckpointsManager()
    let loraModelsManagerPreview = ModelManager<LoraModel>()
    let vaeModelsManagerPreview = ModelManager<VaeModel>()
    let scriptManagerPreview = ScriptManager.preview(withState: .readyToStart)
    return AnyView(EmptyView())
      .environmentObject(promptModelPreview)
      .environmentObject(checkpointsManagerPreview)
      .environmentObject(scriptManagerPreview)
      .environmentObject(loraModelsManagerPreview)
      .environmentObject(vaeModelsManagerPreview)
  }
  
  @MainActor
  static var promptView: some View {
    let promptModelPreview = PromptModel()
    promptModelPreview.positivePrompt = "sample, positive, prompt"
    promptModelPreview.negativePrompt = "sample, negative, prompt"
    promptModelPreview.selectedModel = CheckpointModel(name: "some_model.safetensor", path: "/path/to/checkpoint", type: .python)
    
    let checkpointsManagerPreview = CheckpointsManager()
    let loraModelsManagerPreview = ModelManager<LoraModel>()
    let vaeModelsManagerPreview = ModelManager<VaeModel>()
    
    return PromptView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(checkpointsManagerPreview)
    .environmentObject(loraModelsManagerPreview)
    .environmentObject(vaeModelsManagerPreview)
    .frame(width: 400, height: 600)
  }
  
  @MainActor
  static var contentView: some View {
    let promptModelPreview = PromptModel()
    promptModelPreview.positivePrompt = "sample, positive, prompt"
    promptModelPreview.negativePrompt = "sample, negative, prompt"
    promptModelPreview.selectedModel = CheckpointModel(name: "some_model.safetensor", path: "/path/to/checkpoint", type: .python)
    let checkpointsManagerPreview = CheckpointsManager()
    let loraModelsManagerPreview = ModelManager<LoraModel>()
    let vaeModelsManagerPreview = ModelManager<VaeModel>()
    
    return ContentView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(checkpointsManagerPreview)
    .environmentObject(loraModelsManagerPreview)
    .environmentObject(vaeModelsManagerPreview)
    //.frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity, minHeight: 500, idealHeight: 800, maxHeight: .infinity)
  }
  
}



#Preview("PromptView") {
  CommonPreviews.promptView
}

#Preview("ContentView") {
  CommonPreviews.contentView
}

/*
#Preview {
  PromptView()
    .previewEnvironment
}
*/

extension View {
  func withCommonEnvironment() -> some View {
    let scriptManagerPreview = ScriptManager.preview(withState: .readyToStart)
    return self
      .environmentObject(scriptManagerPreview)
  }
}

extension ScriptManager {
  static func preview(withState state: ScriptState) -> ScriptManager {
    let previewManager = ScriptManager()
    previewManager.scriptState = state
    previewManager.serviceUrl = URL(string: "http://127.0.0.1:7860")
    return previewManager
  }
}
