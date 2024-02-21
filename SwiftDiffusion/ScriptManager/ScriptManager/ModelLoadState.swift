//
//  ModelLoadState.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

enum ModelLoadState: Equatable {
  case launching
  case done
  case isLoading
  case failed
  case idle
}

extension ModelLoadState {
  var statusTest: String {
    switch self {
    case .launching: return "Unpacking" // loading initial
    case .done: return "Done!"
    case .isLoading: return "Loading..." // loading new model
    case .failed: return "Failed"
    case .idle: return "idle"
    }
  }
}

extension ModelLoadState {
  var allowGeneration: Bool {
    switch self {
    case .idle: return true
    case .done: return true
    case .failed: return true
    case .isLoading: return true
    case .launching: return true
    }
  }
}

extension ScriptManager {
  
  @MainActor
  func updateModelLoadState(to state: ModelLoadState) {
    Debug.log("[ScriptManager] updateModelLoadState to: \(state)")
    updateModelLoadStateAndTime(to: state)
    
    if state == .done || state == .failed {
      Delay.by(3) {
        self.modelLoadState = .idle
        self.modelLoadTime = 0
      }
    }
  }
  
  func parseAndUpdateModelLoadState(output: String) async {
    Debug.log(">> \(output)")
    // ie. >> Update successful for model: DreamShaperXL_v2_Turbo_DpmppSDE.safetensors [4726d3bab1].
    if output.contains("Update successful for model") {
      //updateModelLoadStateAndTime(to: .done)
    }
    //Debug.log(output)
    // Check for model loading time
    if let _ = output.range(of: #"Model loaded in ([\d\.]+)s"#, options: .regularExpression) {
      let regex = try! NSRegularExpression(pattern: #"Model loaded in ([\d\.]+)s"#, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: output) {
        let timeString = String(output[timeRange])
        if let time = Double(timeString) {
          //updateModelLoadStateAndTime(to: .done, time: time)
          updateModelLoadTime(with: time)
        }
      }
    }
    
    // Check for failure messages
    let failureMessages = [
      "Stable diffusion model failed to load",
      "TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead."
    ]
    
    if failureMessages.contains(where: output.contains) {
      //updateModelLoadStateAndTime(to: .failed, time: 0)
    }
    // Check for update successful message
    let successRegex = try! NSRegularExpression(pattern: #"Update successful for model:(.*)"#, options: [])
    let successNsRange = NSRange(output.startIndex..<output.endIndex, in: output)
    if let _ = successRegex.firstMatch(in: output, options: [], range: successNsRange) {
      //updateModelLoadStateAndTime(to: .done)
    }
  }
  
  @MainActor
  private func updateModelLoadTime(with time: Double = 0) {
    modelLoadTime = time
    Debug.log("Parsed model load time: \(time)")
  }
  
  /// - important: DEPRECATED
  @MainActor private func updateModelLoadStateAndTime(to state: ModelLoadState, time: Double = 0) {
    self.modelLoadState = state
    self.modelLoadTime = time
    // Assuming Debug.log is a method to log messages
    Debug.log("Model load state updated to \(state) with load time: \(time)")
    
    if state == .done {
      Delay.by(3) {
        self.modelLoadState = .idle
        self.modelLoadTime = 0
      }
    }
    
    if state == .failed {
      Delay.by(3) {
        self.modelLoadState = .idle
        self.modelLoadTime = 0
      }
    }
    
  }
  
  
  
  func updateModelLoadStateBasedOnOutput(output: String) {
    Task {
      await parseAndUpdateModelLoadState(output: output)
    }
  }
  
  
  
}

// .done:
// Model loaded in 4.6s (load weights from disk: 0.4s, create model: 0.7s, apply weights to model: 2.8s, move model to device: 0.2s, calculate empty prompt: 0.4s).
//
// .isLoading:
// Reusing loaded model DreamShaperXL_v2_Turbo_DpmppSDE.safetensors [4726d3bab1] to load v1-5-pruned-emaonly.safetensors [6ce0161689]
//
// Loading weights [6ce0161689] from /Users/jb/Dev/GitHub/stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned-emaonly.safetensors
//
// .failed:
//
// .failedOnLaunch: // can go to other models, but cant go back to model that failed to load
//
// Startup time: 3.3s (import torch: 0.9s, import gradio: 0.4s, setup paths: 0.3s, other imports: 0.4s, load scripts: 0.3s, initialize extra networks: 0.4s, create ui: 0.2s).
//
// Applying attention optimization: sub-quadratic... done.
// ...
// Stable diffusion model failed to load
//
// Applying attention optimization: sub-quadratic... done.

// BIG TELL:
// TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.
