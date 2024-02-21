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
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  //@State var previouslySelectedCheckpointModel: CheckpointModel? = nil
  
  // Alerts
  @State var showSelectedCheckpointModelWasRemovedAlert: Bool = false
  @State var showModelLoadTypeErrorThrownAlert: Bool = false
  
  func consoleLog(_ output: String) {
    scriptManager.apiConsoleOutput += "\(output)\n"
    Debug.log(output)
  }
  
  @MainActor
  func selectMenuItem(withCheckpoint model: CheckpointModel, ofType type: CheckpointModelType = .python) {
    
    /*
    if model == previouslySelectedCheckpointModel {
      consoleLog("> [selectMenuItem] withCheckpoint: \(model.name) is same as previouslySelectedModel: \(String(describing: previouslySelectedCheckpointModel?.name))")
      consoleLog("  [selectMenuItem] cancelling")
      scriptManager.updateModelLoadState(to: .idle)
      return
    }
     */
    
    // if the selected sidebar item is not a workspace item, change the menu title but not the loaded checkpoint
    if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem,
       selectedSidebarItem.isWorkspaceItem == false {
      return
    }
    
    consoleLog("""
    
    > [selectMenuItem] withCheckpoint: model
    
                         model.name: \(model.name)")
    model.checkpointApiModel?.title: \(model.checkpointApiModel?.title ?? "nil")
    
    """)
    
    scriptManager.updateModelLoadState(to: .isLoading)
    
    Task {
      // MARK: POST Load Checkpoint
      let result = await checkpointsManager.postCheckpoint(checkpoint: model)
      switch result {
      case .success():
        consoleLog("[selectMenuItem] Checkpoint was successfully posted.")
      case .failure(let error):
        consoleLog("[selectMenuItem] Failed to post checkpoint: \(error.localizedDescription)")
      }
      
      // MARK: GET Loaded Checkpoint
      let getResult = await checkpointsManager.findLoadedCheckpointModel()
      switch getResult {
      case .success(let checkpointModel):
        if let model = checkpointModel {
          consoleLog("""
          
          [selectMenuItem] Found loaded checkpoint model: \(model.name)
          
          """)
          
          checkpointsManager.loadedCheckpointModel = model
          scriptManager.updateModelLoadState(to: .done)
          
        } else {
          consoleLog("[selectMenuItem] No loaded checkpoint model found")
          checkpointsManager.loadedCheckpointModel = nil
          scriptManager.updateModelLoadState(to: .failed)
        }
        
      case .failure(let error):
        consoleLog("[selectMenuItem] Error: \(error.localizedDescription)")
        checkpointsManager.loadedCheckpointModel = nil
        scriptManager.updateModelLoadState(to: .failed)
      }
    }
    
    //previouslySelectedCheckpointModel = checkpointsManager.loadedCheckpointModel
    
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
                currentPrompt.selectedModel = model
              }
            }
          }
          Section(header: Text("􁻴 Python")) {
            ForEach(checkpointsManager.models.filter { $0.type == .python }) { model in
              Button(model.name) {
                currentPrompt.selectedModel = model
              }
              .disabled(checkpointsManager.hasLoadedInitialCheckpointDataFromApi == false)
            }
          }
        } label: {
          Label(currentPrompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit")
        }
        
        if scriptManager.modelLoadState == .isLoading || checkpointsManager.apiHasLoadedInitialCheckpointModel == false {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
        } else if scriptManager.modelLoadState == .failed {
          Image(systemName: "exclamationmark.octagon.fill")
            .foregroundStyle(Color.red)
        }
      }
      .disabled(scriptManager.modelLoadState.disableCheckpointMenu)
      .onAppear {
        if let sidebarItem = sidebarViewModel.selectedSidebarItem,
           sidebarItem.title == "New Prompt" {
          currentPrompt.selectedModel = nil
        }
      }
      .onChange(of: currentPrompt.selectedModel) {
        if checkpointsManager.apiHasLoadedInitialCheckpointModel,
            let modelToSelect = currentPrompt.selectedModel {
          selectMenuItem(withCheckpoint: modelToSelect)
        }
      }
      .onChange(of: checkpointsManager.loadedCheckpointModel) {
        if let loadedModelCheckpoint = checkpointsManager.loadedCheckpointModel {
          Debug.log("[matchCheckpointState] checkpointsManager.loadedCheckpointModel: \(loadedModelCheckpoint.name)")
        }
      }
      
      .onChange(of: currentPrompt.selectedModel) {
        if let selectedModel = currentPrompt.selectedModel {
          Debug.log("[matchCheckpointState]              currentPrompt.selectedModel: \(selectedModel.name)")
        }
      }
      
      .onChange(of: sidebarViewModel.selectedSidebarItem) {
        Debug.log("sidebarViewModel.selectedSidebarItem.isWorkspaceItem: \(String(describing: sidebarViewModel.selectedSidebarItem?.isWorkspaceItem))")
        
        if let model = currentPrompt.selectedModel {
          selectMenuItem(withCheckpoint: model)
        }
      }
      
      
      .onChange(of: scriptManager.modelLoadTime) {
        if checkpointsManager.apiHasLoadedInitialCheckpointModel == false && scriptManager.modelLoadTime > 0 {
          
          if currentPrompt.selectedModel == nil {
            Task {
              await checkpointsManager.getLoadedCheckpointModelFromApi()
            }
          }
        }
      }
      
      .onChange(of: checkpointsManager.hasLoadedInitialCheckpointDataFromApi) {
        consoleLog(" > .onChange(of: hasLoadedInitialCheckpointDataFromApi), with new value: \(checkpointsManager.hasLoadedInitialCheckpointDataFromApi)")
        if checkpointsManager.hasLoadedInitialCheckpointDataFromApi {
          for model in checkpointsManager.models {
            consoleLog("     \(model.checkpointApiModel?.title ?? "nil")")
          }
        }
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
      .onChange(of: scriptManager.modelLoadTypeErrorThrown) {
        if scriptManager.modelLoadTypeErrorThrown {
          showModelLoadTypeErrorThrownAlert = true
        }
      }
      .alert(isPresented: $showModelLoadTypeErrorThrownAlert) {
        var message: String = ""
       // message.append("Automatic returned the following error: TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.")
        //if let model = currentPrompt.selectedModel { message.append("\(model.name)\n\n") }
        message.append("Don't panic! This is a common issue that is easy to fix.\n\nOpen the Engine Settings and toggle the 'Disable model loading RAM optimizations' option to ON.")
        
        return Alert(
          title: Text("Easily fixable TypeError thrown"),
          message: Text(message),
          primaryButton: .default(Text("Open Engine Settings")) {
            currentPrompt.selectedModel = nil
            scriptManager.modelLoadTypeErrorThrown = false
            WindowManager.shared.showSettingsWindow(withTab: SettingsTab.engine)
          },
          secondaryButton: .cancel(Text("Ignore")) {
            currentPrompt.selectedModel = nil
            scriptManager.modelLoadTypeErrorThrown = false
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
