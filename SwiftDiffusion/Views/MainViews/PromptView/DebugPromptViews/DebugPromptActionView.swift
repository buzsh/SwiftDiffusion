//
//  DebugPromptActionView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptActionView: View {
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  
  @ObservedObject var scriptManager = ScriptManager.shared
  @ObservedObject var userSettings = UserSettings.shared
  
  @State var consoleOutput: String = ""
  
  func setNewConsoleOutputText(_ output: String) {
    consoleOutput = output
    Debug.log(output)
  }
  
  var body: some View {
    if userSettings.showDeveloperInterface {
      HStack {
        Spacer()
        VStack(alignment: .leading) {
          
          if !consoleOutput.isEmpty {
            HStack {
              Spacer()
              Button(action: {
                setNewConsoleOutputText("")
              }) {
                Text("Clear Console")
                  .font(.system(size: 10))
              }
              .buttonStyle(.accessoryBar)
            }
            HStack {
              TextEditor(text: $consoleOutput)
                .font(.system(size: 9, design: .monospaced))
                .frame(minHeight: 10, idealHeight: 30, maxHeight: 80)
            }
            .padding(.vertical, 2)
          }
          
          HStack {
            Spacer()
            Button("Log Prompt") {
              logPromptProperties()
            }
            .padding(.trailing, 6)
            
            Button("Load Models") {
              Debug.log("NO FUNCTION")
              //Task { await checkpointsManager.loadModels() }
            }
            .padding(.trailing, 6)
            
            Spacer()
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


#Preview {
  DebugPromptActionView(scriptManager: ScriptManager.preview(withState: .readyToStart))
    .environmentObject(PromptModel())
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
