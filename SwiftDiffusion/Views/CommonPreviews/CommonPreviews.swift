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
    let modelManagerViewModel = ModelManagerViewModel()
    
    return PromptView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(modelManagerViewModel)
    .frame(width: 400, height: 600)
  }
  
  
  
  
  /*
   #Preview {
     let scriptManagerPreview = ScriptManager.preview(withState: .readyToStart)
     let promptModelPreview = PromptModel()
     promptModelPreview.positivePrompt = "sample, positive, prompt"
     promptModelPreview.negativePrompt = "sample, negative, prompt"
     let modelManager = ModelManagerViewModel()
     return ContentView(modelManagerViewModel: modelManager, scriptManager: scriptManagerPreview, scriptPathInput: .constant("path/to/webui.sh"), fileOutputDir: .constant("path/to/output"), userSettingsModel: UserSettingsModel.preview())
       .environmentObject(promptModelPreview)
       .frame(height: 700)
   }
   */
}

#Preview {
  CommonPreviews.promptView
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
