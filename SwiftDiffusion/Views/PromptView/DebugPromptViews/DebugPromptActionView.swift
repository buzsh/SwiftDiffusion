//
//  DebugPromptActionView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptActionView: View {
  @ObservedObject var scriptManager: ScriptManager
  @ObservedObject var userSettings: UserSettingsModel
  
  @EnvironmentObject var promptModel: PromptModel
  
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
  DebugPromptActionView(scriptManager: ScriptManager.preview(withState: .readyToStart), userSettings: UserSettingsModel.preview())
}

extension DebugPromptActionView {
  func logPromptProperties() {
    var debugOutput = ""
    debugOutput += "selectedModel: \(promptModel.selectedModel?.name ?? "nil")\n"
    debugOutput += "samplingMethod: \(promptModel.samplingMethod ?? "nil")\n"
    debugOutput += "positivePrompt: \(promptModel.positivePrompt)\n"
    debugOutput += "negativePrompt: \(promptModel.negativePrompt)\n"
    debugOutput += "width: \(promptModel.width)\n"
    debugOutput += "height: \(promptModel.height)\n"
    debugOutput += "cfgScale: \(promptModel.cfgScale)\n"
    debugOutput += "samplingSteps: \(promptModel.samplingSteps)\n"
    debugOutput += "seed: \(promptModel.seed)\n"
    debugOutput += "batchCount: \(promptModel.batchCount)\n"
    debugOutput += "batchSize: \(promptModel.batchSize)\n"
    debugOutput += "clipSkip: \(promptModel.clipSkip)\n"
    
    Debug.log(debugOutput)
    scriptManager.updateConsoleOutput(with: debugOutput)
  }
}
