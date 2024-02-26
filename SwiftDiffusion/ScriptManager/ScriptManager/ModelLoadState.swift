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
  /// Determines if image generation should be enabled based on the ModelLoadState (ie. is the "Generate" button)
  var allowGeneration: Bool {
    switch self {
    case .idle:       return true
    case .done:       return true
    case .failed:     return false
    case .isLoading:  return false
    case .launching:  return true
    }
  }
}

extension ScriptManager {
  /// Initiates an asynchronous task to parse the console output and update the model load state accordingly.
  /// - Parameter output: The console output string from the script execution.
  func updateModelLoadStateBasedOnOutput(output: String) {
    Task {
      await parseAndUpdateModelLoadState(output: output)
    }
  }
  
  /// Updates the current model load state to a new state. If the new state is `.done` or `.failed`,
  /// it triggers a delay after which the model load state will reset to `.idle` if not changed in the meantime.
  /// This function must be called from the main thread as it updates the UI.
  /// - Parameter state: The new state to which the model load state will be updated.
  @MainActor func updateModelLoadState(to state: ModelLoadState) {
    modelLoadStateShouldExpire = false
    
    if modelLoadState != state { modelLoadState = state }
    
    Debug.log("[ModelLoadState] updateModelLoadState from: \(modelLoadState.debugInfo) → to: \(state.debugInfo)")
    
    if state == .done || state == .failed {
      modelLoadStateShouldExpire = true
      
      Delay.by(5) {
        if self.modelLoadStateShouldExpire {
          self.updateModelLoadTime(with: 0)
          self.modelLoadState = .idle
        }
      }
    }
  }
  
  /// Updates the model load time. If the new time is different from the current model load time, it updates the time.
  /// If a positive time is provided, it logs the parsed model load time; if zero, it resets the model load time.
  /// This function must be called from the main thread as it may trigger UI updates.
  /// - Parameter time: The new model load time to be set. Defaults to 0, indicating a reset of the model load time.
  @MainActor private func updateModelLoadTime(with time: Double = 0) {
    if modelLoadTime == time { return }
    
    modelLoadTime = time
    
    if time > 0 {
      //updateModelLoadState(to: .done)
      Debug.log("[ModelLoadState] updateModelLoadTime - Parsed model load time: \(time)")
    } else {
      Debug.log("[ModelLoadState] updateModelLoadTime - Resetting model load time to 0")
    }
  }
  
  /// Parses the console output and updates model load state accordingly.
  /// - Parameter output: The console output string to parse.
  func parseAndUpdateModelLoadState(output: String) async {
    Debug.log(">> \(output)")
    
    // Process output messages to update state.
    if isUpdateSuccess(output: output) {
      updateModelLoadState(to: .done)
    } else if let loadTime = extractModelLoadTime(from: output) {
      updateModelLoadTime(with: loadTime)
      
    } else if isGenericModelLoadError(output: output) {
      updateModelLoadState(to: .failed)
      modelLoadErrorString = "Stable diffusion model failed to load"
      
    } else if isTypeErrorThrown(output: output) {
      updateModelLoadState(to: .failed)
      modelLoadTypeErrorThrown = true
    }
  }
  
  /// Checks if the output indicates a successful model update.
  private func isUpdateSuccess(output: String) -> Bool {
    return output.contains("Update successful for model")
  }
  
  /// Extracts model load time from the output, if present.
  private func extractModelLoadTime(from output: String) -> Double? {
    let patterns = [
      #"Model loaded in ([\d\.]+)s"#,
      #"Weights loaded in ([\d\.]+)s"#
    ]
    
    for pattern in patterns {
      if let time = extractFirstMatch(for: pattern, in: output) {
        return time
      }
    }
    
    return nil
  }
  
  /// Checks if the output indicates a generic model loading error.
  private func isGenericModelLoadError(output: String) -> Bool {
    let genericModelLoadErrors = [
      "Stable diffusion model failed to load"
    ]
    
    return genericModelLoadErrors.contains(where: output.contains)
  }
  
  /// Checks if the output indicates a thrown TypeError.
  private func isTypeErrorThrown(output: String) -> Bool {
    let typeErrorMessages = [
      "TypeError: Cannot convert a MPS Tensor to",
      "{'error': 'TypeError', 'detail': '', 'body': '', 'errors': \"Cannot convert a MPS Tensor"
    ]
    
    return typeErrorMessages.contains(where: output.contains)
  }
  
  /// Extracts the first matching double value for a given regex pattern in the provided text.
  /// - Parameters:
  ///   - pattern: The regex pattern to search for.
  ///   - text: The text to search within.
  /// - Returns: The first matching double value, or nil if no match is found.
  private func extractFirstMatch(for pattern: String, in text: String) -> Double? {
    do {
      let regex = try NSRegularExpression(pattern: pattern)
      let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
      if let match = regex.firstMatch(in: text, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: text) {
        return Double(text[timeRange])
      }
    } catch {
      Debug.log("Regex error: \(error.localizedDescription)")
    }
    
    return nil
  }
  
  
  
  //
  // MARK: DEPRECATED
  //
  func OLDparseAndUpdateModelLoadState(output: String) async {
    Debug.log(">> \(output)")
    // ie. >> Update successful for model: DreamShaperXL_v2_Turbo_DpmppSDE.safetensors [4726d3bab1].
    if output.contains("Update successful for model") {
      //updateModelLoadState(to: .done)
    }
    
    // Check for model loading time
    if let _ = output.range(of: #"Model loaded in ([\d\.]+)s"#, options: .regularExpression) {
      let regex = try! NSRegularExpression(pattern: #"Model loaded in ([\d\.]+)s"#, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: output) {
        let timeString = String(output[timeRange])
        if let time = Double(timeString) {
          updateModelLoadTime(with: time)
        }
      }
    }
    
    // Check for thrown TypeError messages
    // ie. TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.
    let typeErrorThrownMessages = [
      "TypeError: Cannot convert a MPS Tensor to"
    ]
    
    if typeErrorThrownMessages.contains(where: output.contains) {
      //updateModelLoadState(to: .failed)
      modelLoadTypeErrorThrown = true
    }
    // Check for update successful message
    let successRegex = try! NSRegularExpression(pattern: #"Update successful for model:(.*)"#, options: [])
    let successNsRange = NSRange(output.startIndex..<output.endIndex, in: output)
    if let _ = successRegex.firstMatch(in: output, options: [], range: successNsRange) {
      //updateModelLoadState(to: .done)
    }
    
    // ie. Weights loaded in 3.5s (send model to cpu: 1.1s, load weights from disk: 0.5s, apply weights to model: 0.7s, move model to device: 1.2s).
    let newPattern = #"Weights loaded in ([\d\.]+)s"#
    do {
      let regex = try NSRegularExpression(pattern: newPattern, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: output) {
        let timeString = String(output[timeRange])
        if let time = Double(timeString) {
          updateModelLoadTime(with: time)
        }
      }
    } catch {
      Debug.log("Regex error: \(error.localizedDescription)")
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
