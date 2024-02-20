//
//  CheckpointMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import SwiftUI

extension ModelLoadState {
  var disableCheckpointMenu: Bool {
    switch self {
    case .done: return false
    case .failed: return true
    case .idle: return false
    case .isLoading: return true
    case .launching: return true
    }
  }
}

struct CheckpointMenu: View {
  @Binding var consoleLog: String
  @ObservedObject var scriptManager: ScriptManager
  var checkpointsManager: CheckpointsManager
  var currentPrompt: PromptModel
  
  @State var showSelectedCheckpointModelWasRemovedAlert: Bool = false
  
  func consoleLog(_ output: String) {
    consoleLog += "\(output)\n"
    Debug.log(output)
  }
  
  func selectMenuItem(withCheckpoint model: CheckpointModel, ofType type: CheckpointModelType = .python) {
    consoleLog("""
    
    > selectedMenuItem withCheckpoint: model
    
                         model.name: \(model.name)")
    model.checkpointApiModel?.title: \(model.checkpointApiModel?.title ?? "nil")
    
    """)
    
    // if previously selected checkpoint != current checkpoint: load new checkpoint
    
    scriptManager.updateModelLoadState(to: .isLoading)
    currentPrompt.selectedModel = model
    
    Task {
      // MARK: POST
      let result = await checkpointsManager.postCheckpoint(checkpoint: model)
      switch result {
      case .success():
        // Handle success, such as updating UI or state
        consoleLog("Checkpoint was successfully posted.")
      case .failure(let error):
        // Handle failure, such as updating UI with an error message
        consoleLog("Failed to post checkpoint: \(error.localizedDescription)")
      }
      
      // MARK: GET
      //await checkpointsManager.handleLoadedCheckpointModel()
      let getResult = await checkpointsManager.findLoadedCheckpointModel()
      switch getResult {
      case .success(let checkpointModel):
        if let model = checkpointModel {
          // Successfully found a model, handle it accordingly
          consoleLog("""
          
          Found loaded checkpoint model: \(model.name)
          
          """)
          
          checkpointsManager.loadedCheckpointModel = model
          scriptManager.updateModelLoadState(to: .done)
          
        } else {
          // No matching model found
          consoleLog("No loaded checkpoint model found")
          checkpointsManager.loadedCheckpointModel = nil
          scriptManager.updateModelLoadState(to: .failed)
          
        }
      case .failure(let error):
        // Handle error
        consoleLog(error.localizedDescription)
        checkpointsManager.loadedCheckpointModel = nil
        scriptManager.updateModelLoadState(to: .failed)
      }
    }
    
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Menu {
          Section(header: Text("􀢇 CoreML")) {
            ForEach(checkpointsManager.models.filter { $0.type == .coreMl }) { model in
              Button(model.name) {
                selectMenuItem(withCheckpoint: model, ofType: .coreMl)
              }
            }
          }
          Section(header: Text("􁻴 Python")) {
            ForEach(checkpointsManager.models.filter { $0.type == .python }) { model in
              Button(model.name) {
                selectMenuItem(withCheckpoint: model)
              }
              .disabled(checkpointsManager.hasLoadedInitialCheckpointDataFromApi == false)
            }
          }
        } label: {
          Label(currentPrompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit")
        }
        
        if scriptManager.modelLoadState == .isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
        } else if scriptManager.modelLoadState == .failed {
          Image(systemName: "exclamationmark.octagon.fill")
            .foregroundStyle(Color.red)
        }
      }
      .disabled(scriptManager.modelLoadState.disableCheckpointMenu)
      .onChange(of: checkpointsManager.hasLoadedInitialCheckpointDataFromApi) {
        consoleLog(" > .onChange(of: hasLoadedInitialCheckpointDataFromApi), with new value: \(checkpointsManager.hasLoadedInitialCheckpointDataFromApi)")
        if checkpointsManager.hasLoadedInitialCheckpointDataFromApi {
          for model in checkpointsManager.models {
            consoleLog("     \(model.checkpointApiModel?.title ?? "nil")")
          }
        }
      }
      
      .onChange(of: scriptManager.modelLoadState) {
        consoleLog("""
        
                        scriptManager.modelLoadState: \(scriptManager.modelLoadState)
                modelLoadState.disableCheckpointMenu: \(scriptManager.modelLoadState.disableCheckpointMenu)
        
        """)
      }
      .onChange(of: checkpointsManager.loadedCheckpointModel) {
        consoleLog("onChange of: checkpointsManager.loadedCheckpointModel")
        if currentPrompt.selectedModel != checkpointsManager.loadedCheckpointModel {
          currentPrompt.selectedModel = checkpointsManager.loadedCheckpointModel
        }
      }
      // MARK: Handle Recently Removed
      .onChange(of: checkpointsManager.recentlyRemovedCheckpointModels) {
        handleRecentlyRemovedCheckpointIfSelectedMenuItem()
      }
      .alert(isPresented: $showSelectedCheckpointModelWasRemovedAlert) {
        var message: String = ""
        if let model = currentPrompt.selectedModel { message = model.name }
        
        return Alert(
          title: Text("Warning: Model checkpoint was either moved or deleted"),
          message: Text(message),
          dismissButton: .cancel(Text("OK")) {
            currentPrompt.selectedModel = nil
          }
        )
      }
    }
  }
  
  func handleRecentlyRemovedCheckpointIfSelectedMenuItem() {
    if !checkpointsManager.recentlyRemovedCheckpointModels.isEmpty, let selectedModel = currentPrompt.selectedModel {
      for removedModel in checkpointsManager.recentlyRemovedCheckpointModels {
        if selectedModel.path == removedModel.path {
          showSelectedCheckpointModelWasRemovedAlert = true
        }
      }
    }
    checkpointsManager.recentlyRemovedCheckpointModels = []
  }
  
}
