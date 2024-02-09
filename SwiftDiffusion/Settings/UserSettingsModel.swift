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
  
  
}
