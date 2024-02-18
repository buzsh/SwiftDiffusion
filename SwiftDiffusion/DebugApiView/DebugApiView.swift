//
//  DebugApiView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import SwiftUI

extension Constants.WindowSize {
  struct DebugApi {
    static let defaultWidth: CGFloat = 1520
    static let defaultHeight: CGFloat = 1080
  }
}

struct DebugApiView: View {
  @ObservedObject var scriptManager: ScriptManager
  var currentPrompt: PromptModel
  var sidebarViewModel: SidebarViewModel
  var checkpointModelsManager: CheckpointModelsManager
  var loraModelsManager: ModelManager<LoraModel>
  
  @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
  @State private var consoleLog: String = ""
  
  var apiUrl: String {
    if let url = scriptManager.serviceUrl {
      return url.absoluteString
    }
    return "nil"
  }
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      
    } content: {
      VStack(alignment: .leading, spacing: 0) {
        DebugPromptStatusView(scriptManager: scriptManager)
        TextEditor(text: $scriptManager.consoleOutput)
          .font(.system(size: 10, weight: .regular, design: .monospaced))
          .background(Color.black)
      }
      .navigationSplitViewColumnWidth(min: 410, ideal: 410, max: 700)
      
    } detail: {
      VStack(alignment: .leading, spacing: 0) {
        
        HStack {
          CheckpointMenu(consoleLog: $consoleLog, scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointModelsManager: checkpointModelsManager)
            .onChange(of: currentPrompt.selectedModel) {
              if let selectedModel = currentPrompt.selectedModel {
                consoleLog += ".onChange(of: currentPrompt.selectedModel)\n"
                consoleLog += "    \(selectedModel)\n\n"
              }
            }
          
          
          Button("API Button") {
            Debug.log("API Button")
          }
          
          Spacer()
        }
        .frame(height: 40)
        
        Divider()
        
        TextEditor(text: $consoleLog)
      }
      .padding(.horizontal, 6)
      .font(.system(size: 12, weight: .regular, design: .monospaced))
      .buttonStyle(.accessoryBar)
      
    }
    .navigationTitle("Debug API")
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          Text(apiUrl)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
          
          Button(action: {
            if let url = scriptManager.serviceUrl {
              NSWorkspace.shared.open(url)
            }
          }) {
            Image(systemName: "network")
          }
        }
      }
    }
  }
}


#Preview {
  let scriptManagerPreview: ScriptManager = .preview(withState: .active)
  let promptModelPreview = PromptModel()
  promptModelPreview.positivePrompt = "sample, positive, prompt"
  promptModelPreview.negativePrompt = "sample, negative, prompt"
  promptModelPreview.selectedModel = CheckpointModel(name: "some_model.safetensor", type: .python, url: URL(fileURLWithPath: "."), isDefaultModel: false)
  let sidebarViewModelPreview = SidebarViewModel()
  let checkpointModelsManagerPreview = CheckpointModelsManager()
  let loraModelsManagerPreview = ModelManager<LoraModel>()
  return DebugApiView(scriptManager: scriptManagerPreview, currentPrompt: promptModelPreview, sidebarViewModel: sidebarViewModelPreview, checkpointModelsManager: checkpointModelsManagerPreview, loraModelsManager: loraModelsManagerPreview)
}
