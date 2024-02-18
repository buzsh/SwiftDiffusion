//
//  ScriptState.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

enum ScriptState: Equatable {
  case readyToStart
  case launching
  case active
  case isTerminating
  case terminated
  case unableToLocateScript
  //case error
}

extension ScriptManager {
  var scriptStateText: String {
    switch scriptState {
    case .readyToStart:
      return "Ready to start"
    case .launching:
      return "Launching service..."
    case .active:
      if let urlString = self.serviceUrl?.absoluteString {
        return "Active (\(urlString.replacingOccurrences(of: "http://", with: "")))"
      } else {
        Debug.log("Unable to get absoluteString of '\(String(describing: self.serviceUrl))'")
        return "Active"
      }
    case .isTerminating:
      return "Terminating..."
    case .terminated:
      return "Terminated"
    case .unableToLocateScript:
      return "Error: Unable to start script"
    }
  }
}

extension ScriptState {
  var statusColor: Color {
    switch self {
    case .readyToStart: return Color.gray
    case .launching: return Color.yellow
    case .active: return Color.green
    case .isTerminating: return Color.yellow
    case .terminated: return Color.red
    case .unableToLocateScript: return Color.red
    }
  }
  var isActive: Bool {
    if case .active = self {
      return true
    } else {
      return false
    }
  }
  
  var isAwaitingProcessToPlayOut: Bool {
    switch self {
    case .readyToStart: return false
    case .launching: return true
    case .active: return false
    case .isTerminating: return true
    case .terminated: return true
    case .unableToLocateScript: return false
    }
  }
  
  var isStartable: Bool {
    switch self {
    case .readyToStart: return true
    case .launching: return false
    case .active: return false
    case .isTerminating: return false
    case .terminated: return true
    case .unableToLocateScript: return true
    }
  }
  
  var isTerminatable: Bool {
    switch self {
    case .readyToStart: return false
    case .launching: return true
    case .active: return true
    case .isTerminating: return false
    case .terminated: return false
    case .unableToLocateScript: return false
    }
  }
}
