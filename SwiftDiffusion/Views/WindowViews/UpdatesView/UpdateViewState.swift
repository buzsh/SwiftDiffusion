//
//  UpdateViewState.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/3/24.
//

import SwiftUI

enum UpdateViewState {
  case defaultState
  case latestVersion
  case checkingForUpdate
  case newVersionAvailable
  
  var statusText: String {
    switch self {
    case .defaultState: "Haven't checked for updates."
    case .latestVersion: "You are on the latest version."
    case .checkingForUpdate: "Checking for new update..."
    case .newVersionAvailable: "There's a new version available!"
    }
  }
  
  var symbol: String {
    switch self {
    case .defaultState: "icloud.slash.fill"
    case .latestVersion: "checkmark.circle.fill"
    case .checkingForUpdate: "arrow.triangle.2.circlepath.icloud.fill"
    case .newVersionAvailable: "exclamationmark.circle.fill"
    }
  }
  
  var symbolColor: Color {
    switch self {
    case .defaultState: Color.secondary
    case .latestVersion: Color.green
    case .checkingForUpdate: Color.yellow
    case .newVersionAvailable: Color.blue
    }
  }
  
  var mainButtonText: String {
    switch self {
    case .defaultState: "Check for Updates"
    case .latestVersion: "Check for Updates"
    case .checkingForUpdate: "Checking for Updates..."
    case .newVersionAvailable: "Download Now"
    }
  }
  
}
