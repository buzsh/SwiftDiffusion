//
//  SettingsTab.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

enum SettingsTab: String {
  case general = "General"
  case files = "Files"
  case prompt = "Prompt"
  case engine = "Engine"
  case developer = "Developer"
  
  var symbol: String {
    switch self {
    case .general: return "gearshape"
    case .files: return "doc.on.doc"
    case .prompt: return "text.bubble"
    case .engine: return "arkit"
    case .developer: return "hammer"
    }
  }
  
  var hasHelpIndicators: Bool {
    switch self {
    case .general: return true
    case .files: return false
    case .prompt: return true
    case .engine: return true
    case .developer: return true
    }
  }
  
  var sectionHeaderText: String {
    switch self {
    case .general: return "General"
    case .files: return "Automatic Paths"
    case .prompt: return "Prompt"
    case .engine: return "Engine"
    case .developer: return "Developer"
    }
  }
}


extension SettingsTab: CaseIterable, Identifiable {
  var id: Self { self }
}


#Preview {
  SettingsView()
}
