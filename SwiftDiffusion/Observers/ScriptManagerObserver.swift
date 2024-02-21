//
//  ScriptManagerObserver.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import SwiftUI
import Combine

@MainActor
class ScriptManagerObserver {
  var scriptManager: ScriptManager
  var userSettings: UserSettings
  var checkpointsManager: CheckpointsManager
  var loraModelsManager: ModelManager<LoraModel>
  
  private var cancellables: Set<AnyCancellable> = []
  
  init(scriptManager: ScriptManager, userSettings: UserSettings, checkpointsManager: CheckpointsManager, loraModelsManager: ModelManager<LoraModel>) {
    self.scriptManager = scriptManager
    self.userSettings = userSettings
    self.checkpointsManager = checkpointsManager
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
      checkpointsManager.startObservingDirectory()
      loraModelsManager.startObservingDirectory()
      
      if let serviceUrl = scriptManager.serviceUrl {
        checkpointsManager.configureApiManager(with: serviceUrl.absoluteString)
      }
      
    } else {
      checkpointsManager.stopObservingDirectory()
      loraModelsManager.stopObservingDirectory()
    }
  }
  
  private func stableDiffusionModelsPathDidChange(_ newPath: String) {
    Debug.log("stableDiffusionModelsPathDidChange newPath: \(newPath)")
    checkpointsManager.stopObservingDirectory()
    checkpointsManager.startObservingDirectory()
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
