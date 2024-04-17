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
  @ObservedObject var scriptManager = ScriptManager.shared
  
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  
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
  
  func consoleLog(_ output: String) {
    scriptManager.apiConsoleOutput += "\(output)\n"
    Debug.log(output)
  }
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      
    } content: {
      VStack(alignment: .leading, spacing: 0) {
        
        DebugPromptStatusView()
        
        TextEditor(text: $scriptManager.consoleOutput)
          .font(.system(size: 10, weight: .regular, design: .monospaced))
          .background(Color.black)
          .foregroundColor(.white)
      }
      .navigationSplitViewColumnWidth(min: 410, ideal: 410, max: 700)
      
    } detail: {
      VStack(alignment: .leading, spacing: 0) {
        
        HStack(alignment: .bottom) {
          CheckpointMenu()
          
          Button("local titles") {
            consoleLog("local title")
            for model in checkpointsManager.models {
              consoleLog(" - \(model.name)")
            }
          }
          
          Button("local paths") {
            consoleLog("local path")
            for model in checkpointsManager.models {
              consoleLog += " - \(model.path)"
            }
          }
          
          Button("api title") {
            consoleLog("api title")
            for model in checkpointsManager.models {
              if let title = model.checkpointApiModel?.title {
                consoleLog(" - \(title)")
              }
            }
          }
          
          Button("api filename") {
            consoleLog("api filename")
            for model in checkpointsManager.models {
              if let apiFilename = model.checkpointApiModel?.filename {
                consoleLog(" - \(apiFilename)")
              }
            }
          }
          Spacer()
        }
        .frame(height: 70)
        .font(.system(size: 12, weight: .regular, design: .rounded))
        .padding(.bottom, 6)
        
        Divider()
        
        TextEditor(text: $scriptManager.apiConsoleOutput)
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
            Image(systemName: SFSymbol.network.name)
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
  let checkpointsManagerPreview = CheckpointsManager()
  let loraModelsManagerPreview = ModelManager<LoraModel>()
  return DebugApiView()
    .environmentObject(scriptManagerPreview)
    .environmentObject(checkpointsManagerPreview)
    .environmentObject(promptModelPreview)
    .environmentObject(loraModelsManagerPreview)
}
