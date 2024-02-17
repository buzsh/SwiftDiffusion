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
  
  var modelManagerViewModel: ModelManagerViewModel
  var loraModelsManager: ModelManager<LoraModel>
  
  private var cancellables: Set<AnyCancellable> = []
  
  init(scriptManager: ScriptManager, userSettings: UserSettings, modelManagerViewModel: ModelManagerViewModel, loraModelsManager: ModelManager<LoraModel>) {
    self.scriptManager = scriptManager
    self.userSettings = userSettings
    self.modelManagerViewModel = modelManagerViewModel
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
    
    userSettings.$stableDiffusionModelsPath
      .sink { [weak self] newPath in
        self?.stableDiffusionModelsPathDidChange(newPath)
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
      modelManagerViewModel.startObservingModelDirectories()
      loraModelsManager.startObservingDirectory()
    }
  }
  
  private func stableDiffusionModelsPathDidChange(_ newPath: String) {
    Debug.log("stableDiffusionModelsPathDidChange newPath: \(newPath)")
    modelManagerViewModel.stopObservingModelDirectories()
    modelManagerViewModel.startObservingModelDirectories()
  }
  
  private func loraDirectoryPathDidChange(_ newPath: String = "") {
    Debug.log("loraDirectoryPathDidChange newPath: \(newPath)")
    loraModelsManager.stopObservingDirectory()
    loraModelsManager.startObservingDirectory()
  }
  
  deinit {
      print("ScriptManagerObserver is being deinitialized")
  }
}
