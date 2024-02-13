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
    let modelManagerViewModel = ModelManagerViewModel()
    let scriptManager = ScriptManager.preview(withState: .readyToStart)
    return AnyView(EmptyView())
      .environmentObject(promptModelPreview)
      .environmentObject(modelManagerViewModel)
      .environmentObject(scriptManager)
  }
  
  @MainActor
  static var promptView: some View {
    let promptModelPreview = PromptModel()
    promptModelPreview.positivePrompt = "sample, positive, prompt"
    promptModelPreview.negativePrompt = "sample, negative, prompt"
    promptModelPreview.selectedModel = ModelItem(name: "some_model.safetensor", type: .python, url: URL(fileURLWithPath: "."), isDefaultModel: false)
    let modelManagerViewModel = ModelManagerViewModel()
    return PromptView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(modelManagerViewModel)
    .frame(width: 400, height: 600)
  }
  
  @MainActor
  static var contentView: some View {
    let promptModelPreview = PromptModel()
    promptModelPreview.positivePrompt = "sample, positive, prompt"
    promptModelPreview.negativePrompt = "sample, negative, prompt"
    promptModelPreview.selectedModel = ModelItem(name: "some_model.safetensor", type: .python, url: URL(fileURLWithPath: "."), isDefaultModel: false)
    let modelManagerViewModel = ModelManagerViewModel()
    
    return ContentView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(modelManagerViewModel)
    .frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity,
           minHeight: 500, idealHeight: 800, maxHeight: .infinity)
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
    //let promptModel = PromptModel()
    let scriptManager = ScriptManager.preview(withState: .readyToStart)
    return self
      .environmentObject(scriptManager)
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

extension ScriptManager {
  /// DEPRECATED: Use `ScriptManager().preview(withState: .readyToStart)`
  static func readyPreview() -> ScriptManager {
    let previewManager = ScriptManager()
    previewManager.scriptState = .readyToStart // .active
    return previewManager
  }
}
