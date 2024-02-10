//
//  CommonPreviews.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct CommonPreviews {
  
  @MainActor
  static var promptView: some View {
    let modelManager = ModelManagerViewModel()
    let promptModel = PromptViewModel()
    promptModel.positivePrompt = "sample, positive, prompt"
    promptModel.negativePrompt = "sample, negative, prompt"
    
    return PromptView(
      prompt: promptModel,
      modelManager: modelManager,
      scriptManager: ScriptManager.readyPreview(),
      userSettings: UserSettingsModel.preview()
    )
    .frame(width: 400, height: 600)
  }
  
  @MainActor
  static var previewEnvironment: some View {
    let modelManager = ModelManagerViewModel()
    let scriptManager = ScriptManager.readyPreview()
    let userSettings = UserSettingsModel.preview()
    
    return AnyView(EmptyView())
      .environmentObject(modelManager)
      .environmentObject(scriptManager)
      .environmentObject(userSettings)
  }
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
    let scriptManager = ScriptManager.readyPreview()
    let userSettings = UserSettingsModel.preview()
    return self
      .environmentObject(scriptManager)
      .environmentObject(userSettings)
  }
}

/*
struct MyView_Previews: PreviewProvider {
  static var previews: some View {
    CommonPreviews.promptView
  }
}
 */
