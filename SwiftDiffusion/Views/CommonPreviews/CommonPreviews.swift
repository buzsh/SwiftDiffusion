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
    let promptModel = PromptModel()
    let modelManager = ModelManagerViewModel()
    let scriptManager = ScriptManager.preview(withState: .readyToStart)
    let userSettings = UserSettingsModel.preview()
    
    return AnyView(EmptyView())
      .environmentObject(promptModel)
      .environmentObject(modelManager)
      .environmentObject(scriptManager)
      .environmentObject(userSettings)
  }
  
  @MainActor
  static var promptView: some View {
    let modelManager = ModelManagerViewModel()
    let promptModel = PromptModel()
    promptModel.positivePrompt = "sample, positive, prompt"
    promptModel.negativePrompt = "sample, negative, prompt"
    
    return PromptView(
      modelManager: modelManager,
      scriptManager: ScriptManager.preview(withState: .readyToStart),
      userSettings: UserSettingsModel.preview()
    )
    .environmentObject(promptModel)
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
    let userSettings = UserSettingsModel.preview()
    return self
      .environmentObject(scriptManager)
      .environmentObject(userSettings)
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

extension UserSettingsModel {
  static func preview() -> UserSettingsModel {
    let previewManager = UserSettingsModel()
    return previewManager
  }
}
