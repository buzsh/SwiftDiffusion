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
}

extension ModelLoadState {
  var statusTest: String {
    switch self {
    case .launching: return "[Launch] Unpacking"
    case .done: return "Done!"
    case .isLoading: return "Loading..."
    case .failed: return "Failed"
    case .failedOnLaunch: return "[Launch] Failed unpacking"
    }
  }
}

extension ScriptManager {
  func parseAndUpdateModelLoadState(output: String) async {
    // Check for "Model loaded" message
    if output.starts(with: "Model loaded in ") {
      let timeString = output.replacingOccurrences(of: "Model loaded in ", with: "").replacingOccurrences(of: "s", with: "")
      if let time = Double(timeString) {
        await updateModelLoadState(state: .done, time: time)
      }
    }
    // Check for failure messages
    else if output.starts(with: "Stable diffusion model failed to load") ||
              output.contains("TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.") {
      await updateModelLoadState(state: .failed, time: 0)
    }
  }
  
  @MainActor
  func updateModelLoadState(state: ModelLoadState, time: Double) {
    modelLoadState = state
    modelLoadTime = time
    Debug.log(state == .done ? "Model loaded in \(time) seconds" : "Model load failed")
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
