//
//  ScriptState.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

enum ScriptState {
  case readyToStart
  case launching
  case active(String)
  case isTerminating
  case terminated
}

extension ScriptState {
  var statusColor: Color {
    switch self {
    case .readyToStart: return Color.gray
    case .launching: return Color.yellow
    case .active(_): return Color.green
    case .isTerminating: return Color.yellow
    case .terminated: return Color.red
    }
  }
  var isActive: Bool {
    if case .active(_) = self {
      return true
    } else {
      return false
    }
  }
  
  var isStartable: Bool {
    switch self {
    case .readyToStart: return true
    case .launching: return false
    case .active(_): return false
    case .isTerminating: return false
    case .terminated: return true
    }
  }
  
  var isTerminatable: Bool {
    switch self {
    case .readyToStart: return false
    case .launching: return true
    case .active(_): return true
    case .isTerminating: return false
    case .terminated: return false
    }
  }
}