//
//  ScriptManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation
import SwiftUI

extension Constants.CommandLine {
  
  static let baseArgs = "--nowebui --api --api-log --no-half --no-download-sd-model"
  
  
  static var defaultCommand: (String, String) -> String = { dir, name in
    let disableModelLoadingRamOptimizations = UserSettings.shared.disableModelLoadingRamOptimizations
    if UserSettings.shared.disableModelLoadingRamOptimizations {
      Debug.log("disableModelLoadingRamOptimizations: \(disableModelLoadingRamOptimizations)")
      return "cd \(dir); ./\(name) \(baseArgs) --disable-model-loading-ram-optimization"
    }
    return "cd \(dir); ./\(name) \(baseArgs)"
  }
}

enum ScriptResult {
  case success(String)
  case failure(Error)
}

extension Constants.Delays {
  static let secondsBetweenTerminatedAndReadyState: Double = 2
}

class ScriptManager: ObservableObject {
  @ObservedObject var userSettings = UserSettings.shared
  
  static let shared = ScriptManager()
  private var pythonProcess: PythonProcess?
  
  @Published var serviceUrl: URL? = nil
  
  private var originalLaunchBrowserLine: String?
  
  var shouldTrimOutput: Bool = false
  
  @Published var genStatus: GenerationStatus = .idle
  @Published var genProgress: Double = 0
  
  @Published var genIterationPerSecond: String = ""
  @Published var genCurrentStepOutOfTotalSteps: String = ""
  
  @Published var modelLoadState: ModelLoadState = .idle
  @Published var modelLoadTime: Double = 0
  @Published var modelLoadStateShouldExpire: Bool = false
  @Published var modelLoadTypeErrorThrown: Bool = false
  
  @Published var modelLoadErrorString: String? = nil
  
  @Published var scriptState: ScriptState = .readyToStart
  @Published var consoleOutput: String = ""
  
  @Published var apiConsoleOutput: String = ""
  
  @Published var mostRecentApiRequestPayload: String = "{}"
  
  func updateScriptState(_ state: ScriptState) {
    Debug.log("[ScriptManager] updateScriptState: \(state.debugInfo)")
    self.scriptState = state
    
    if state == .terminated || state == .unableToLocateScript {
      handleUiOnTermination()
      Delay.by(Constants.Delays.secondsBetweenTerminatedAndReadyState) {
        self.scriptState = .readyToStart
        self.modelLoadState = .idle
      }
    }
  }
  
  func handleUiOnTermination() {
    genStatus = .idle
    genProgress = 0
    modelLoadState = .idle
    modelLoadTime = 0
  }
  /// Updates the console output with a new message.
  /// - Parameter message: The message to be added to the console output.
  func updateConsoleOutput(with message: String) {
    DispatchQueue.main.async {
      self.consoleOutput += "\(message)\n"
    }
  }
  /// Updates the console output with a new debug message.
  /// - Parameter message: The debug message to be added to the console output.
  private func updateDebugConsoleOutput(with message: String) {
    Debug.perform {
      self.updateConsoleOutput(with: message)
    }
  }
  /// Sets variables for new run script state.
  func newRunScriptState() {
    Debug.log("Starting ./webui.sh")
    updateScriptState(.launching)
    //modelLoadState = .launching
    serviceUrl = nil
  }
  
  func performRequiredPathsCheck() {
    guard !userSettings.webuiShellPath.isEmpty else {
      Debug.log("[run] userSettings.webuiShellPath is empty")
      updateScriptState(.unableToLocateScript)
      return
    }
    guard !userSettings.stableDiffusionModelsPath.isEmpty else {
      Debug.log("[run] userSettings.stableDiffusionModelsPath is empty")
      modelLoadState = .failed
      return
    }
  }
  
  func run() {
    newRunScriptState()
    
    performRequiredPathsCheck()
    
    guard let (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(userSettings.webuiShellPath) else {
      Debug.log("GUARD: (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(userSettings.webuiShellPath)")
      return }
    
    pythonProcess = PythonProcess()
    pythonProcess?.delegate = self
    pythonProcess?.runScript(at: scriptDirectory, scriptName: scriptName)
  }
  /// Terminates the script execution.
  /// - Parameter completion: A closure that is called with the result of the termination attempt.
  ///
  /// **Usage**
  ///
  /// ```swift
  /// terminate() // or
  /// terminate { result in
  ///   switch result {
  ///   case .success(let message):
  ///     print(message)
  ///   case .failure(let error):
  ///     print("An error occurred: \(error)")
  ///   }
  /// }
  func terminate(completion: @escaping (ScriptResult) -> Void = { _ in }) {
    updateScriptState(.isTerminating)
    pythonProcess?.terminate()
    
    if userSettings.killAllPythonProcessesOnTerminate {
      terminateAllPythonProcesses()
    } else {
      pythonProcess?.terminate()
    }
    
    // Handle post-termination logic
    
    completion(.success("Process terminated successfully."))
    updateScriptState(.terminated)
  }
  
  /// Terminates the script execution immediately.
  func terminateImmediately() {
    pythonProcess?.terminate()
    updateScriptState(.terminated)
    Debug.log("Process terminated immediately.")
  }
  
  func parseServiceUrl(from output: String) {
    if serviceUrl == nil, output.contains("running on") {
      let pattern = "running on (https?://[\\w\\.-]+(:\\d+)?(/[\\w\\./-]*)?)"
      do {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
        if let match = regex.firstMatch(in: output, options: [], range: nsRange) {
          let urlRange = Range(match.range(at: 1), in: output)!
          let url = String(output[urlRange])
          self.serviceUrl = URL(string: url)
          DispatchQueue.main.async {
            self.updateScriptState(.active)
            Debug.log("serviceURL successfully parsed from console: \(url)")
          }
        } else {
          Debug.log("No URL match found.")
        }
      } catch {
        Debug.log("Regex error: \(error)")
      }
    }
  }
  
}
