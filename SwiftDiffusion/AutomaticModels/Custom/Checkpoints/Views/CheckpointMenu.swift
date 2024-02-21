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
  @ObservedObject var scriptManager = ScriptManager.shared
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  
  @State var hasLoadedInitialCheckpoint: Bool = false
  
  @State var showSelectedCheckpointModelWasRemovedAlert: Bool = false
  
  @State var previouslySelectedCheckpointModel: CheckpointModel? = nil
  
  func consoleLog(_ output: String) {
    scriptManager.apiConsoleOutput += "\(output)\n"
    Debug.log(output)
  }
  
  @MainActor
  func selectMenuItem(withCheckpoint model: CheckpointModel, ofType type: CheckpointModelType = .python) {
    
    if model == previouslySelectedCheckpointModel {
      consoleLog("> selectedMenuItem withCheckpoint: \(model.name) is same as previouslySelectedModel: \(String(describing: previouslySelectedCheckpointModel?.name))")
      consoleLog("  selectedMenuItem cancelling")
      scriptManager.updateModelLoadState(to: .idle)
      return
    }
    
    consoleLog("""
    
    > selectedMenuItem withCheckpoint: model
    
                         model.name: \(model.name)")
    model.checkpointApiModel?.title: \(model.checkpointApiModel?.title ?? "nil")
    
    """)
    
    scriptManager.updateModelLoadState(to: .isLoading)
    
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
    
    previouslySelectedCheckpointModel = checkpointsManager.loadedCheckpointModel
    
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      PromptRowHeading(title: "Checkpoint")
        .padding(.bottom, 6)
      HStack {
        Menu {
          Section(header: Text("􀢇 CoreML")) {
            ForEach(checkpointsManager.models.filter { $0.type == .coreMl }) { model in
              Button(model.name) {
                //selectMenuItem(withCheckpoint: model, ofType: .coreMl)
                currentPrompt.selectedModel = model
              }
            }
          }
          Section(header: Text("􁻴 Python")) {
            ForEach(checkpointsManager.models.filter { $0.type == .python }) { model in
              Button(model.name) {
                //selectMenuItem(withCheckpoint: model)
                currentPrompt.selectedModel = model
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
          hasLoadedInitialCheckpoint = true
        }
      }
      
      .onChange(of: currentPrompt.selectedModel) {
        if hasLoadedInitialCheckpoint, let modelToSelect = currentPrompt.selectedModel {
          selectMenuItem(withCheckpoint: modelToSelect)
          //selectMenuItem(withCheckpoint: currentPrompt.selectedModel, ofType: .python)
        }
        Debug.log(".onChange(of: currentPrompt.selectedModel)")
      }
      .onChange(of: checkpointsManager.loadedCheckpointModel) {
        consoleLog("onChange of: checkpointsManager.loadedCheckpointModel")
        if currentPrompt.selectedModel != checkpointsManager.loadedCheckpointModel {
          currentPrompt.selectedModel = checkpointsManager.loadedCheckpointModel
        }
      }
      
      .onChange(of: scriptManager.modelLoadState) {
        consoleLog("""
        
                        scriptManager.modelLoadState: \(scriptManager.modelLoadState)
                 scriptManager.disableCheckpointMenu: \(scriptManager.modelLoadState.disableCheckpointMenu)
        
        """)
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

#Preview {
  CommonPreviews.promptView
}