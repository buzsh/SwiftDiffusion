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
  
  @State private var checkpoints: [Checkpoint] = []
  @State private var checkpointTitlePaths: [String: String] = [:]
  private func updateCheckpointTitlePaths(with checkpoints: [Checkpoint]) {
    checkpointTitlePaths = Dictionary(uniqueKeysWithValues: checkpoints.map { ($0.name, $0.path) })
  }
  
  @State private var checkpointApiTitle: String = ""
  
  private func logConsoleCheckpointTitlePaths() {
    consoleLog += "\n\nlogConsoleCheckpointTitlePaths()\n"
    for (name, path) in checkpointTitlePaths {
      consoleLog += "    name: \(name)\n"
      consoleLog += "    path: \(path)\n\n"
    }
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
          CheckpointMenu(consoleLog: $consoleLog, scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointModelsManager: checkpointModelsManager)
            .onChange(of: currentPrompt.selectedModel) {
              if let selectedModel = currentPrompt.selectedModel {
                consoleLog += ".onChange(of: currentPrompt.selectedModel)\n"
                consoleLog += "    \(selectedModel)\n\n"
              }
            }
          
          Button("Refresh/Get [Checkpoints]") {
            let apiManager = APIManager(baseURL: apiUrl)
            Task {
              let result = await refreshAndGetCheckpoints(apiManager: apiManager)
              switch result {
              case .success(let message):
                Debug.log(message)
                consoleLog += "Done: \(message)\n"
                checkpoints = apiManager.checkpoints
                updateCheckpointTitlePaths(with: checkpoints)
              case .failure(let error):
                Debug.log(error.localizedDescription)
                consoleLog += "Error: \(error.localizedDescription)\n"
              }
            }
          }
          
          Button("Log [Checkpoints]") {
            logConsoleCheckpointTitlePaths()
          }
          
          Button("Get Loaded Checkpoint") {
            let apiManager = APIManager(baseURL: apiUrl)
            Task {
              let result = await getLoadedCheckpoint(apiManager: apiManager)
              switch result {
              case .success(let message):
                Debug.log(message)
                consoleLog += "Done: \(message)\n"
                if let title = apiManager.loadedCheckpoint {
                  checkpointApiTitle = title
                }
                consoleLog += "[Loaded] from sd_model_checkpoint: \(checkpointApiTitle)\n"
              case .failure(let error):
                Debug.log(error.localizedDescription)
                consoleLog += "Error: \(error.localizedDescription)\n"
              }
            }
          }
          
          Button("Set [Checkpoints]") {
            Debug.log("Hello")//logConsoleCheckpointTitlePaths()
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
  
  func refreshAndGetCheckpoints(apiManager: APIManager) async -> Result<String, Error> {
    Debug.log("\n\nrefreshAndGetCheckpoints")
    do {
      consoleLog += "apiManager init\n"
      try await apiManager.refreshCheckpointsAsync()
      consoleLog += "apiManager.refreshCheckpointsAsync()\n"
      try await apiManager.getCheckpointsAsync()
      consoleLog += "apiManager.getCheckpointsAsync()\n"
      return .success("Success!")
    } catch {
      return .failure(error)
    }
  }
  
  func getLoadedCheckpoint(apiManager: APIManager) async -> Result<String, Error> {
    Debug.log("\n\ngetLoadedCheckpoint")
    do {
      consoleLog += "apiManager init\n"
      try await apiManager.getLoadedCheckpointAsync()
      consoleLog += "apiManager.getLoadedCheckpointAsync()\n"
      return .success("Success!")
    } catch {
      return .failure(error)
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
