//
//  UserSettings.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation
import Combine

/// `UserSettings` manages the user preferences for the application, persisting settings across app launches.
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
  /// Indicates whether all Python processes should be terminated when the app is terminated.
  /// - important: There is currently no external implementation for handling when the app is exited from Xcode's developer interface.
  /// As a result, all Python processes launched during runtime will persist if the application is exited in this manor. Enabling this option will not resolve this issue,
  /// but it does allow you to kill all Python processes from previous app runetime states when terminated via the "Stop" square action in the toolbar.
  /// - Note: Python processes launched within the regular application runtime–outside of the developer environment–are handled via
  /// AppDelegate's `applicationShouldTerminate` method.
  @Published var killAllPythonProcessesOnTerminate: Bool {
    didSet { store.set(killAllPythonProcessesOnTerminate, forKey: "killAllPythonProcessesOnTerminate") }
  }
  /// Indicates whether the Python environment should automatically start at app launch. This is the default state for non-development runtimes.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var alwaysStartPythonEnvironmentAtLaunch: Bool {
    didSet { store.set(alwaysStartPythonEnvironmentAtLaunch, forKey: "alwaysStartPythonEnvironmentAtLaunch") }
  }
  /// Controls the visibility of Python environment controls within the app's UI. Namely, the application toolbar.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var showPythonEnvironmentControls: Bool {
    didSet { store.set(showPythonEnvironmentControls, forKey: "showPythonEnvironmentControls") }
  }
  
  private let initialShowPythonEnvironmentControlsKey = "initialShowPythonEnvironmentControls"
  /// Stores the initial state of `showPythonEnvironmentControls` to restore it later if needed.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
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
  /// Controls the visibility of the developer interface within the app's UI.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`. Additionally,
  ///   changing this property may automatically update `showPythonEnvironmentControls` based on certain conditions.
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
  /// Initialize persisting UserDefaults for UserSettings and optionally set default values.
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
  /// Resets the user settings to their default values.
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
  /// Updates the visibility state of Python environment controls based on the current state of the developer interface.
  /// If the developer interface is enabled, `showPythonEnvironmentControls` is forcibly set to true and its initial state is saved.
  /// If the developer interface is disabled, `showPythonEnvironmentControls` is restored to its initial state.
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
