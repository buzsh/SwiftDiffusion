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
  
  @Published var webuiShellPath: String {
    didSet { store.set(webuiShellPath, forKey: "webuiShellPath") }
  }
  
  @Published var stableDiffusionModelsPath: String {
    didSet { store.set(stableDiffusionModelsPath, forKey: "stableDiffusionModelsPath") }
  }
  
  @Published var outputDirectoryPath: String {
    didSet { store.set(outputDirectoryPath, forKey: "outputDirectoryPath") }
  }
  
  @Published var killAllPythonProcessesOnTerminate: Bool {
    didSet { store.set(killAllPythonProcessesOnTerminate, forKey: "killAllPythonProcessesOnTerminate") }
  }
  
  @Published var alwaysStartPythonEnvironmentAtLaunch: Bool {
    didSet { store.set(alwaysStartPythonEnvironmentAtLaunch, forKey: "alwaysStartPythonEnvironmentAtLaunch") }
  }
  
  @Published var showDebugMenu: Bool {
    didSet { store.set(showDebugMenu, forKey: "showDebugMenu") }
  }
  
  @Published var disablePasteboardParsingForGenerationData: Bool {
    didSet { store.set(disablePasteboardParsingForGenerationData, forKey: "disablePasteboardParsingForGenerationData") }
  }
  
  @Published var alwaysShowPasteboardGenerationDataButton: Bool {
    didSet { store.set(alwaysShowPasteboardGenerationDataButton, forKey: "alwaysShowPasteboardGenerationDataButton") }
  }
  
  @Published var disableModelLoadingRamOptimizations: Bool {
    didSet { store.set(disableModelLoadingRamOptimizations, forKey: "disableModelLoadingRamOptimizations") }
  }
  
  private init() {
    let defaults: [String: Any] = [ // default settings
      "alwaysStartPythonEnvironmentAtLaunch": true
    ]
    store.register(defaults: defaults)
    
    self.webuiShellPath = store.string(forKey: "webuiShellPath") ?? ""
    self.stableDiffusionModelsPath = store.string(forKey: "stableDiffusionModelsPath") ?? ""
    self.outputDirectoryPath = store.string(forKey: "outputDirectoryPath") ?? ""
    self.killAllPythonProcessesOnTerminate = store.bool(forKey: "killAllPythonProcessesOnTerminate")
    self.alwaysStartPythonEnvironmentAtLaunch = store.bool(forKey: "alwaysStartPythonEnvironmentAtLaunch")
    self.showDebugMenu = store.bool(forKey: "showDebugMenu")
    self.disablePasteboardParsingForGenerationData = store.bool(forKey: "disablePasteboardParsingForGenerationData")
    self.alwaysShowPasteboardGenerationDataButton = store.bool(forKey: "alwaysShowPasteboardGenerationDataButton")
    self.disableModelLoadingRamOptimizations = store.bool(forKey: "disableModelLoadingRamOptimizations")
  }
  
  func restoreDefaults() {
    outputDirectoryPath = ""
    killAllPythonProcessesOnTerminate = false
    alwaysStartPythonEnvironmentAtLaunch = true
    showDebugMenu = false
    disablePasteboardParsingForGenerationData = false
    alwaysShowPasteboardGenerationDataButton = false
    disableModelLoadingRamOptimizations = false
  }
  
  
  // MARK: URLs from Paths
  
  var stableDiffusionModelsDirectoryUrl: URL? {
    guard !stableDiffusionModelsPath.isEmpty else { return nil }
    let pathUrl = URL(fileURLWithPath: stableDiffusionModelsPath)
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: stableDiffusionModelsPath, isDirectory: &isDir), isDir.boolValue {
      return pathUrl
    } else {
      return nil
    }
  }
  
  var outputDirectoryUrl: URL? {
    let fileManager = FileManager.default
    var directoryUrl: URL?
    
    if !outputDirectoryPath.isEmpty {
      directoryUrl = URL(fileURLWithPath: outputDirectoryPath)
    } else if let documentsDirectoryUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      directoryUrl = documentsDirectoryUrl.appendingPathComponent("SwiftDiffusion")
    }
    
    if let url = directoryUrl {
      do {
        try FileUtility.ensureDirectoryExists(at: url)
        return url
      } catch {
        Debug.log("Failed to ensure directory exists: \(error.localizedDescription)")
        return nil
      }
    }
    
    return nil
  }
  
  
}
