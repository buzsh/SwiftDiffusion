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
  var checkpointsManager: CheckpointsManager
  var currentPrompt: PromptModel
  var sidebarViewModel: SidebarViewModel
  var loraModelsManager: ModelManager<LoraModel>
  
  @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
  @State private var consoleLog: String = ""
  
  @State private var checkpoints: [CheckpointModel] = []
  @State private var checkpointTitlePaths: [String: String] = [:]
  private func updateCheckpointTitlePaths(with checkpoints: [CheckpointModel]) {
    checkpointTitlePaths = Dictionary(uniqueKeysWithValues: checkpoints.map { ($0.name, $0.path) })
  }
  
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
          CheckpointMenu(consoleLog: $consoleLog, scriptManager: scriptManager, checkpointsManager: checkpointsManager, currentPrompt: currentPrompt)
          
          Button("local titles") {
            consoleLog += "\n\nlocal title\n"
            for model in checkpointsManager.models {
              consoleLog += " - \(model.name)\n"
            }
          }
          
          Button("local paths") {
            consoleLog += "\n\nlocal path\n"
            for model in checkpointsManager.models {
              consoleLog += " - \(model.path)\n"
            }
          }
          
          Button("api title") {
            consoleLog += "\n\napi title\n"
            for model in checkpointsManager.models {
              if let title = model.checkpointApiModel?.title {
                consoleLog += " - \(title)\n"
              }
            }
          }
          
          Button("api filename") {
            consoleLog += "\n\napi filename\n"
            for model in checkpointsManager.models {
              if let apiFilename = model.checkpointApiModel?.filename {
                consoleLog += " - \(apiFilename)\n"
              }
            }
          }
          
          Spacer()
        }
        .frame(height: 40)
        .font(.system(size: 12, weight: .regular, design: .rounded))
        
        Divider()
        
        TextEditor(text: $consoleLog)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
      }
      .padding(.horizontal, 6)
      
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
  promptModelPreview.selectedModel = CheckpointModel(name: "some_model.safetensor", path: "/path/to/checkpoint", type: .python)
  let sidebarViewModelPreview = SidebarViewModel()
  let checkpointsManagerPreview = CheckpointsManager()
  let loraModelsManagerPreview = ModelManager<LoraModel>()
  return DebugApiView(scriptManager: scriptManagerPreview, checkpointsManager: checkpointsManagerPreview, currentPrompt: promptModelPreview, sidebarViewModel: sidebarViewModelPreview, loraModelsManager: loraModelsManagerPreview)
}
