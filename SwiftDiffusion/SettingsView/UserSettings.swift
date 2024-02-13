//
//  UserSettings.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
  static let shared = UserSettings()
  let store = UserDefaults.standard
  
  @Published var alwaysShowSettingsHelp: Bool {
    didSet { store.set(alwaysShowSettingsHelp, forKey: "alwaysShowSettingsHelp") }
  }
  
  // MARK: - File Path Settings
  @Published var webuiShellPath: String {
    didSet { store.set(webuiShellPath, forKey: "webuiShellPath") }
  }
  
  @Published var stableDiffusionModelsPath: String {
    didSet { store.set(stableDiffusionModelsPath, forKey: "stableDiffusionModelsPath") }
  }
  
  @Published var outputDirectoryPath: String {
    didSet { store.set(outputDirectoryPath, forKey: "outputDirectoryPath") }
  }
  
  // MARK: - Developer Settings
  @Published var killAllPythonProcessesOnTerminate: Bool {
    didSet { store.set(killAllPythonProcessesOnTerminate, forKey: "killAllPythonProcessesOnTerminate") }
  }
  
  @Published var alwaysStartPythonEnvironmentAtLaunch: Bool {
    didSet { store.set(alwaysStartPythonEnvironmentAtLaunch, forKey: "alwaysStartPythonEnvironmentAtLaunch") }
  }

  @Published var showPythonEnvironmentControls: Bool {
    didSet { store.set(showPythonEnvironmentControls, forKey: "showPythonEnvironmentControls") }
  }
  
  private let initialShowPythonEnvironmentControlsKey = "initialShowPythonEnvironmentControls"
  private var initialShowPythonEnvironmentControls: Bool? {
    get {
      if let value = store.value(forKey: initialShowPythonEnvironmentControlsKey) as? Bool {
        return value
      }
      return nil
    }
    set {
      store.set(newValue, forKey: initialShowPythonEnvironmentControlsKey)
    }
  }
  
  @Published var showDeveloperInterface: Bool {
    didSet {
      store.set(showDeveloperInterface, forKey: "showDeveloperInterface")
      updateEnvironmentControlsBasedOnDeveloperInterface()
    }
  }
  
  // MARK: - Prompt Settings
  @Published var disablePasteboardParsingForGenerationData: Bool {
    didSet { store.set(disablePasteboardParsingForGenerationData, forKey: "disablePasteboardParsingForGenerationData") }
  }
  
  @Published var alwaysShowPasteboardGenerationDataButton: Bool {
    didSet { store.set(alwaysShowPasteboardGenerationDataButton, forKey: "alwaysShowPasteboardGenerationDataButton") }
  }
  
  // MARK: Engine Settings
  @Published var disableModelLoadingRamOptimizations: Bool {
    didSet { store.set(disableModelLoadingRamOptimizations, forKey: "disableModelLoadingRamOptimizations") }
  }
  
  
  // MARK: - Init Default Values
  private init() {
    let defaults: [String: Any] = [ // default settings
      "alwaysStartPythonEnvironmentAtLaunch": true,
      "alwaysShowSettingsHelp": true
    ]
    store.register(defaults: defaults)
    
    self.alwaysShowSettingsHelp = store.bool(forKey: "alwaysShowSettingsHelp")
    self.webuiShellPath = store.string(forKey: "webuiShellPath") ?? ""
    self.stableDiffusionModelsPath = store.string(forKey: "stableDiffusionModelsPath") ?? ""
    self.outputDirectoryPath = store.string(forKey: "outputDirectoryPath") ?? ""
    self.killAllPythonProcessesOnTerminate = store.bool(forKey: "killAllPythonProcessesOnTerminate")
    self.alwaysStartPythonEnvironmentAtLaunch = store.bool(forKey: "alwaysStartPythonEnvironmentAtLaunch")
    self.showDeveloperInterface = store.bool(forKey: "showDeveloperInterface")
    self.showPythonEnvironmentControls = store.bool(forKey: "showPythonEnvironmentControls")
    self.disablePasteboardParsingForGenerationData = store.bool(forKey: "disablePasteboardParsingForGenerationData")
    self.alwaysShowPasteboardGenerationDataButton = store.bool(forKey: "alwaysShowPasteboardGenerationDataButton")
    self.disableModelLoadingRamOptimizations = store.bool(forKey: "disableModelLoadingRamOptimizations")
  }
  
  func restoreDefaults() {
    outputDirectoryPath = ""
    killAllPythonProcessesOnTerminate = false
    alwaysStartPythonEnvironmentAtLaunch = true
    showDeveloperInterface = false
    showPythonEnvironmentControls = false
    disablePasteboardParsingForGenerationData = false
    alwaysShowPasteboardGenerationDataButton = false
    disableModelLoadingRamOptimizations = false
  }
}

extension UserSettings {
  func updateEnvironmentControlsBasedOnDeveloperInterface() {
    if showDeveloperInterface {
      if initialShowPythonEnvironmentControls == nil {
        initialShowPythonEnvironmentControls = showPythonEnvironmentControls
      }
      showPythonEnvironmentControls = true
    } else {
      if let initialState = initialShowPythonEnvironmentControls {
        showPythonEnvironmentControls = initialState
        store.removeObject(forKey: initialShowPythonEnvironmentControlsKey)
      }
    }
  }
}
