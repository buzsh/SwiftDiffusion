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
  case failedOnLaunch
  case idle
}

extension ModelLoadState {
  var statusTest: String {
    switch self {
    case .launching: return "[Launch] Unpacking"
    case .done: return "Done!"
    case .isLoading: return "Loading..."
    case .failed: return "Failed"
    case .failedOnLaunch: return "[Launch] Failed unpacking"
    case .idle: return "idle"
    }
  }
}

extension ScriptManager {
  
  func parseAndUpdateModelLoadState(output: String) async {
    Debug.log(output)
    // Adjusted regular expression to allow for extra text after the initial match
    if let loadedRange = output.range(of: #"Model loaded in ([\d\.]+)s"#, options: .regularExpression) {
      let timeString = String(output[loadedRange])
      // The previous logic to extract the numerical value might also need adjustment
      // Extract just the numerical value directly using the regex capture group
      let regex = try! NSRegularExpression(pattern: #"Model loaded in ([\d\.]+)s"#, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: output) {
        let timeString = String(output[timeRange])
        if let time = Double(timeString) {
          await updateModelLoadStateAndTime(to: .done, time: time)
        }
      }
    }
    
    let failureMessages = [
      "Stable diffusion model failed to load",
      "TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead."
    ]
    
    if failureMessages.contains(where: output.contains) {
      await updateModelLoadStateAndTime(to: .failed, time: 0)
    }
  }
  
  
  @MainActor
  private func updateModelLoadStateAndTime(to state: ModelLoadState, time: Double) {
    self.modelLoadState = state
    self.modelLoadTime = time
    // Assuming Debug.log is a method to log messages
    Debug.log("Model load state updated to \(state) with load time: \(time)")
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
