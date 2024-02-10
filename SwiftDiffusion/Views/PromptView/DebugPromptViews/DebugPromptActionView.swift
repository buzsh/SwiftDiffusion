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
  @ObservedObject var prompt: PromptViewModel
  
  var body: some View {
    if userSettings.showDebugMenu {
      HStack {
        Spacer()
        VStack(alignment: .leading) {
          Button("Log Prompt") {
            logPromptProperties()
          }
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

/*
#Preview {
  DebugPromptActionView(userSettings: UserSettingsModel.preview(),
                        prompt: PromptViewModel())
}
*/

extension DebugPromptActionView {
  func logPromptProperties() {
    var debugOutput = ""
    debugOutput += "selectedModel: \(prompt.selectedModel?.name ?? "nil")\n"
    debugOutput += "samplingMethod: \(prompt.samplingMethod ?? "nil")\n"
    debugOutput += "positivePrompt: \(prompt.positivePrompt)\n"
    debugOutput += "negativePrompt: \(prompt.negativePrompt)\n"
    debugOutput += "width: \(prompt.width)\n"
    debugOutput += "height: \(prompt.height)\n"
    debugOutput += "cfgScale: \(prompt.cfgScale)\n"
    debugOutput += "samplingSteps: \(prompt.samplingSteps)\n"
    debugOutput += "seed: \(prompt.seed)\n"
    debugOutput += "batchCount: \(prompt.batchCount)\n"
    debugOutput += "batchSize: \(prompt.batchSize)\n"
    debugOutput += "clipSkip: \(prompt.clipSkip)\n"
    
    Debug.log(debugOutput)
    scriptManager.updateConsoleOutput(with: debugOutput)
  }
}
