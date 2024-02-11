//
//  DebugPromptActionView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptActionView: View {
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var userSettings: UserSettingsModel
  
  @ObservedObject var scriptManager: ScriptManager
  
  var body: some View {
    if userSettings.showDebugMenu {
      HStack {
        Spacer()
        VStack(alignment: .leading) {
          Button("Log Prompt") {
            logPromptProperties()
          }
          //.padding(.trailing, 6)
        }
        .padding(.horizontal)
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color.white)
        Spacer()
      }
      .padding(.vertical, 6).padding(.bottom, 2)
      .background(Color.black)
    }
  }
}


#Preview {
  CommonPreviews.promptView
}


#Preview {
  DebugPromptActionView(scriptManager: ScriptManager.preview(withState: .readyToStart))
    .environmentObject(PromptModel())
    .environmentObject(UserSettingsModel.preview())
}

extension DebugPromptActionView {
  func logPromptProperties() {
    var debugOutput = ""
    debugOutput += "selectedModel: \(currentPrompt.selectedModel?.name ?? "nil")\n"
    debugOutput += "samplingMethod: \(currentPrompt.samplingMethod ?? "nil")\n"
    debugOutput += "positivePrompt: \(currentPrompt.positivePrompt)\n"
    debugOutput += "negativePrompt: \(currentPrompt.negativePrompt)\n"
    debugOutput += "width: \(currentPrompt.width)\n"
    debugOutput += "height: \(currentPrompt.height)\n"
    debugOutput += "cfgScale: \(currentPrompt.cfgScale)\n"
    debugOutput += "samplingSteps: \(currentPrompt.samplingSteps)\n"
    debugOutput += "seed: \(currentPrompt.seed)\n"
    debugOutput += "batchCount: \(currentPrompt.batchCount)\n"
    debugOutput += "batchSize: \(currentPrompt.batchSize)\n"
    debugOutput += "clipSkip: \(currentPrompt.clipSkip)\n"
    
    Debug.log(debugOutput)
    scriptManager.updateConsoleOutput(with: debugOutput)
  }
}
