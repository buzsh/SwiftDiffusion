//
//  UserSettingsModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation
import SwiftUI

class UserSettingsModel: ObservableObject {
  static let shared = UserSettingsModel()
  
  @AppStorage("alwaysStartPythonEnvironmentAtLaunch") var alwaysStartPythonEnvironmentAtLaunch: Bool = true
  @AppStorage("showDebugMenu") var showDebugMenu: Bool = false
  
  @AppStorage("disablePasteboardParsingForGenerationData") var disablePasteboardParsingForGenerationData: Bool = false
  @AppStorage("alwaysShowPasteboardGenerationDataButton") var alwaysShowPasteboardGenerationDataButton: Bool = false
  
  @AppStorage("stableDiffusionModelsPath") var stableDiffusionModelsPath: String = ""
  @AppStorage("userOutputDirectoryPath") var userOutputDirectoryPath: String = ""
  
  @AppStorage("disableModelLoadingRamOptimizations") var disableModelLoadingRamOptimizations: Bool = false
  
  @AppStorage("killAllPythonProcessesOnTerminate") var killAllPythonProcessesOnTerminate: Bool = false
  

  
  func restoreDefaults() {
    alwaysStartPythonEnvironmentAtLaunch = true
    showDebugMenu = false
    disablePasteboardParsingForGenerationData = false
    alwaysShowPasteboardGenerationDataButton = false
    stableDiffusionModelsPath = ""
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
  
  var userOutputDirectoryUrl: URL? {
    if !userOutputDirectoryPath.isEmpty {
      let pathUrl = URL(fileURLWithPath: userOutputDirectoryPath)
      var isDir: ObjCBool = false
      if FileManager.default.fileExists(atPath: userOutputDirectoryPath, isDirectory: &isDir), isDir.boolValue {
        return pathUrl
      }
    }
    return nil
  }
  
  
}
