//
//  ScriptManagerObserver.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import SwiftUI
import Combine

class ScriptManagerObserver {
  var scriptManager: ScriptManager
  var userSettings: UserSettings
  
  /// DEPRECATED
  var modelManagerViewModel: ModelManagerViewModel
  
  var optionsModelManager: OptionsModelManager
  var pythonCheckpointModelsManager: ModelManager<PythonCheckpointModel>
  var loraModelsManager: ModelManager<LoraModel>
  
  private var cancellables: Set<AnyCancellable> = []
  
  init(scriptManager: ScriptManager, userSettings: UserSettings, modelManagerViewModel: ModelManagerViewModel, pythonCheckpointModelsManager: ModelManager<PythonCheckpointModel>, optionsModelManager: OptionsModelManager, loraModelsManager: ModelManager<LoraModel>) {
    self.scriptManager = scriptManager
    self.userSettings = userSettings
    self.modelManagerViewModel = modelManagerViewModel
    
    self.optionsModelManager = optionsModelManager
    self.pythonCheckpointModelsManager = pythonCheckpointModelsManager
    self.loraModelsManager = loraModelsManager
    
    setupObservers()
  }
  
  private func setupObservers() {
    scriptManager.$scriptState
      .print("scriptState Stream")
      .sink { [weak self] newState in
        self?.scriptStateDidChange(newState)
      }
      .store(in: &cancellables)
    
    /// DEPRECATED
    /*
    userSettings.$stableDiffusionModelsPath
      .sink { [weak self] newPath in
        self?.stableDiffusionModelsPathDidChange(newPath)
      }
      .store(in: &cancellables)
    */
    userSettings.$pythonCheckpointModelsPath
      .sink { [weak self] newPath in
        self?.pythonCheckpointDirectoryPathDidChange(newPath)
      }
      .store(in: &cancellables)
    
    userSettings.$loraDirectoryPath
      .sink { [weak self] newPath in
        self?.loraDirectoryPathDidChange(newPath)
      }
      .store(in: &cancellables)
  }
  
  private func scriptStateDidChange(_ newState: ScriptState) {
    Debug.log("scriptStateDidChange newState: \(newState)")
    if newState.isActive {
      Debug.log("newState.isActive")
      //modelManagerViewModel.startObservingModelDirectories()
      
      pythonCheckpointModelsManager.startObservingDirectory()
      
      optionsModelManager.fetchOptionsModel()
      
      loraModelsManager.startObservingDirectory()
    }
  }
  
  /// DEPRECATED
  private func stableDiffusionModelsPathDidChange(_ newPath: String) {
    Debug.log("stableDiffusionModelsPathDidChange newPath: \(newPath)")
    modelManagerViewModel.stopObservingModelDirectories()
    modelManagerViewModel.startObservingModelDirectories()
  }
  
  private func pythonCheckpointDirectoryPathDidChange(_ newPath: String = "") {
    Debug.log("pythonCheckpointDirectoryPathDidChange newPath: \(newPath)")
    pythonCheckpointModelsManager.stopObservingDirectory()
    pythonCheckpointModelsManager.startObservingDirectory()
  }
  
  private func loraDirectoryPathDidChange(_ newPath: String = "") {
    Debug.log("loraDirectoryPathDidChange newPath: \(newPath)")
    loraModelsManager.stopObservingDirectory()
    loraModelsManager.startObservingDirectory()
  }
  
  deinit {
    Debug.log("ScriptManagerObserver is being deinitialized")
  }
}
