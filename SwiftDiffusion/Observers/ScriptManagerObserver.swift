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
  var vaeModelsManager: ModelManager<VaeModel>
  
  private var cancellables: Set<AnyCancellable> = []
  
  init(scriptManager: ScriptManager, userSettings: UserSettings, checkpointsManager: CheckpointsManager, loraModelsManager: ModelManager<LoraModel>, vaeModelsManager: ModelManager<VaeModel>) {
    self.scriptManager = scriptManager
    self.userSettings = userSettings
    self.checkpointsManager = checkpointsManager
    self.loraModelsManager = loraModelsManager
    self.vaeModelsManager = vaeModelsManager
    
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
    
    userSettings.$vaeDirectoryPath
      .sink { [weak self] newPath in
        self?.vaeDirectoryPathDidChange(newPath)
      }
      .store(in: &cancellables)
  }
  
  
  private func scriptStateDidChange(_ newState: ScriptState) {
    Debug.log("[ScriptManagerObserver] scriptStateDidChange newState: \(newState)")
    if newState.isActive {
      Debug.log("[ScriptManagerObserver] newState.isActive")
      checkpointsManager.startObservingDirectory()
      loraModelsManager.startObservingDirectory()
      vaeModelsManager.startObservingDirectory()
      
      if let serviceUrl = scriptManager.serviceUrl {
        checkpointsManager.configureApiManager(with: serviceUrl.absoluteString)
      }
      
    } else {
      checkpointsManager.stopObservingDirectory()
      loraModelsManager.stopObservingDirectory()
      vaeModelsManager.stopObservingDirectory()
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
  
  private func vaeDirectoryPathDidChange(_ newPath: String = "") {
    Debug.log("vaeDirectoryPathDidChange newPath: \(newPath)")
    vaeModelsManager.stopObservingDirectory()
    vaeModelsManager.startObservingDirectory()
  }
  
  deinit {
    Debug.log("ScriptManagerObserver is being deinitialized")
  }
}
