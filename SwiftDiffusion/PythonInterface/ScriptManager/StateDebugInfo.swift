//
//  StateDebugInfo.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import Foundation

extension ScriptState {
  var debugInfo: String {
    switch self {
    case .readyToStart:   return ".readyToStart"
    case .launching:      return ".launching"
    case .active:         return ".active"
    case .isTerminating:  return ".isTerminating"
    case .terminated:     return ".terminated"
    }
  }
}

extension GenerationStatus {
  var debugInfo: String {
    switch self {
    case .idle: return ".idle"
    case .preparingToGenerate: return ".preparingToGenerate"
    case .generating: return ".generating"
    case .finishingUp: return ".finishingUp"
    case .done: return ".done"
    }
  }
}

extension ModelLoadState {
  var debugInfo: String {
    switch self {
    case .launching: return ".launching"
    case .done: return ".done"
    case .isLoading: return ".isLoading"
    case .failed: return ".failed"
    case .idle: return ".idle"
    }
  }
}
