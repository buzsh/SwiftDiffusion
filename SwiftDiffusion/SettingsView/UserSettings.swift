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
  
  /// Indicates whether help descriptions in the SettingsView should always be shown to the user.
  /// Enabling this provides users with more context for each setting, potentially improving usability.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var alwaysShowSettingsHelp: Bool {
    didSet { store.set(alwaysShowSettingsHelp, forKey: "alwaysShowSettingsHelp") }
  }
  
  
  // MARK: - File Path Settings
  /// Path to the Automatic1111's webui.sh shell script used by the application.
  /// This path is persisted across app launches and is used to execute Automatic1111's web UI shell script.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var webuiShellPath: String {
    didSet { store.set(webuiShellPath, forKey: "webuiShellPath") }
  }
  /// Path to the directory containing the Stable Diffusion models.
  /// This setting is essential for the application to locate and use the stable diffusion model checkpoints.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var stableDiffusionModelsPath: String {
    didSet { store.set(stableDiffusionModelsPath, forKey: "stableDiffusionModelsPath") }
  }
  /// Custom directory path chosen by the user for saving image outputs.
  /// Allows users to specify a preferred location for saving generated images.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var outputDirectoryPath: String {
    didSet { store.set(outputDirectoryPath, forKey: "outputDirectoryPath") }
  }
  
  
  // MARK: - Developer Settings
  /// Indicates whether all Python processes should be terminated when the app is terminated.
  /// - Warning: There is currently no external implementation for handling when the app is exited from Xcode's developer interface.
  /// As a result, all Python processes launched during runtime will persist if the application is exited in this manor. Enabling this option will not resolve this issue,
  /// but it does allow you to kill all Python processes from previous app runetime states when terminated via the "Stop" square action in the toolbar.
  /// - Important: Python processes launched within the regular application runtime–outside of the developer environment–are handled via
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
  /// Controls whether automatic parsing of generation data from the clipboard is disabled.
  /// When enabled, the app will not automatically parse and format generation data copied from external sources such as Civit.ai.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var disablePasteboardParsingForGenerationData: Bool {
    didSet { store.set(disablePasteboardParsingForGenerationData, forKey: "disablePasteboardParsingForGenerationData") }
  }
  /// Determines if the 'Paste Generation Data' button is always visible, regardless of clipboard content compatibility. Enabling this will also disablePasteboardParsingForGenerationData.
  /// This can be useful for users who don't want their clipboards constantly being parsed for new generation data by the application.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
  @Published var alwaysShowPasteboardGenerationDataButton: Bool {
    didSet { store.set(alwaysShowPasteboardGenerationDataButton, forKey: "alwaysShowPasteboardGenerationDataButton") }
  }
  
  // MARK: Engine Settings
  /// Disables RAM optimizations during model loading.
  /// This setting may help resolve issues related to model loading errors–such as MPS, BFloat16, BFloat32. However, it can increase load times significantly.
  /// - Warning: Enabling this setting can significantly increase the time it takes to load models. Only enable this if the console is returning issues involving MPS, BFloat16, BFloat32.
  /// - Note: Changes to this property are automatically persisted to `UserDefaults`.
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
