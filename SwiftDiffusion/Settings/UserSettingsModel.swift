//
//  UserSettingsModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
  static let shared = UserSettings()
  let store = UserDefaults.standard
  
  //@AppStorage("disableModelLoadingRamOptimizations") var disableModelLoadingRamOptimizations: Bool = false
  
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
    self.stableDiffusionModelsPath = store.string(forKey: "stableDiffusionModelsPath") ?? ""
    self.outputDirectoryPath = store.string(forKey: "outputDirectoryPath") ?? ""
    self.killAllPythonProcessesOnTerminate = store.bool(forKey: "killAllPythonProcessesOnTerminate")
    self.alwaysStartPythonEnvironmentAtLaunch = store.bool(forKey: "alwaysStartPythonEnvironmentAtLaunch") // default value should be true
    self.showDebugMenu = store.bool(forKey: "showDebugMenu")
    self.disablePasteboardParsingForGenerationData = store.bool(forKey: "disablePasteboardParsingForGenerationData")
    self.alwaysShowPasteboardGenerationDataButton = store.bool(forKey: "alwaysShowPasteboardGenerationDataButton")
    self.disableModelLoadingRamOptimizations = store.bool(forKey: "disableModelLoadingRamOptimizations")
  }
  
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
    if !outputDirectoryPath.isEmpty {
      let pathUrl = URL(fileURLWithPath: outputDirectoryPath)
      var isDir: ObjCBool = false
      if FileManager.default.fileExists(atPath: outputDirectoryPath, isDirectory: &isDir), isDir.boolValue {
        return pathUrl
      }
    }
    return nil
  }
  
  func restoreDefaults() {
    alwaysStartPythonEnvironmentAtLaunch = true
    showDebugMenu = false
    disablePasteboardParsingForGenerationData = false
    alwaysShowPasteboardGenerationDataButton = false
    //stableDiffusionModelsPath = ""
  }
}

/*
import Foundation
import SwiftUI

class UserSettingsModel: ObservableObject {
  
  @AppStorage("alwaysStartPythonEnvironmentAtLaunch") var alwaysStartPythonEnvironmentAtLaunch: Bool = true
  @AppStorage("showDebugMenu") var showDebugMenu: Bool = false
  @AppStorage("disablePasteboardParsingForGenerationData") var disablePasteboardParsingForGenerationData: Bool = false
  @AppStorage("alwaysShowPasteboardGenerationDataButton") var alwaysShowPasteboardGenerationDataButton: Bool = false
  //@AppStorage("stableDiffusionModelsPath") var stableDiffusionModelsPath: String = ""
  //@AppStorage("userOutputDirectoryPath") var userOutputDirectoryPath: String = ""
  @AppStorage("disableModelLoadingRamOptimizations") var disableModelLoadingRamOptimizations: Bool = false
  //@AppStorage("killAllPythonProcessesOnTerminate") var killAllPythonProcessesOnTerminate: Bool = false
  
  func restoreDefaults() {
    alwaysStartPythonEnvironmentAtLaunch = true
    showDebugMenu = false
    disablePasteboardParsingForGenerationData = false
    alwaysShowPasteboardGenerationDataButton = false
    //stableDiffusionModelsPath = ""
  }
  
}
*/
