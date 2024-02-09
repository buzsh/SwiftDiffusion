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
  
  
  func restoreDefaults() {
    alwaysStartPythonEnvironmentAtLaunch = true
    showDebugMenu = false
    disablePasteboardParsingForGenerationData = false
    alwaysShowPasteboardGenerationDataButton = false
  }
}
