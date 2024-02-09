//
//  UserSettingsModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

class UserSettingsModel: ObservableObject {
  static let shared = UserSettingsModel()
  
  @Published var showDebugMenu: Bool = false
  
  @Published var disablePasteboardParsingForGenerationData: Bool = false
  @Published var alwaysShowPasteboardGenerationDataButton: Bool = false
}
