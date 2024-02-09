//
//  UserSettingsModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

class UserSettingsModel: ObservableObject {
  static let shared = UserSettingsModel()
  
  @Published var showAllDescriptions: Bool {
    didSet {
      UserDefaults.standard.set(showAllDescriptions, forKey: "showAllDescriptions")
    }
  }
  
  init() {
    self.showAllDescriptions = UserDefaults.standard.bool(forKey: "showAllDescriptions")
  }
  
  @Published var alwaysStartPythonEnvironmentAtLaunch: Bool = true
  @Published var showDebugMenu: Bool = false
  
  @Published var disablePasteboardParsingForGenerationData: Bool = false
  @Published var alwaysShowPasteboardGenerationDataButton: Bool = false
}
