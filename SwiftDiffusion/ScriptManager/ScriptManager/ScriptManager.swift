//
//  ScriptManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation
import SwiftUI

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
  
  private let configManager: ConfigFileManager?
  private var originalLaunchBrowserLine: String?
  
  var shouldTrimOutput: Bool = false
  
  @Published var genStatus: GenerationStatus = .idle
  @Published var genProgress: Double = 0
  
  @Published var modelLoadState: ModelLoadState = .idle
  @Published var modelLoadTime: Double = 0
  
  @Published var scriptState: ScriptState = .readyToStart
  @Published var consoleOutput: String = ""
  /// Initializes a new instance of `ScriptManager`.
  init() {
    self.configManager = ConfigFileManager(scriptPath: UserSettings.shared.webuiShellPath)
  }
  
  func updateScriptState(_ state: ScriptState) {
    Debug.log("[ScriptManager] updateScriptState: \(state.debugInfo)")
    self.scriptState = state
    
    if scriptState == .active {
      Delay.by(3) {
        self.restoreLaunchBrowserInConfigJson()
      }
    }
    
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
    
    disableLaunchBrowserInConfigJson()
    
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
      restoreLaunchBrowserInConfigJson()
    }
    
    // Handle post-termination logic
    
    completion(.success("Process terminated successfully."))
    updateScriptState(.terminated)
  }
  
  /// Terminates the script execution immediately.
  func terminateImmediately() {
    pythonProcess?.terminate()
    restoreLaunchBrowserInConfigJson()
    updateScriptState(.terminated)
    Debug.log("Process terminated immediately.")
  }
  
  func disableLaunchBrowserInConfigJson() {
    guard let configManager = self.configManager else {
      updateDebugConsoleOutput(with: "Error: ConfigFileManager is not initialized.")
      return
    }
    
    configManager.disableLaunchBrowser { [weak self] result in
      switch result {
      case .success(let originalLine):
        self?.originalLaunchBrowserLine = originalLine
        self?.updateDebugConsoleOutput(with: "[config.json] >> \(originalLine)")
        self?.updateDebugConsoleOutput(with: "[config.json] << \(Constants.ConfigFile.autoLaunchBrowserDisabled)")
        self?.updateDebugConsoleOutput(with: "[config.json] successfully modified")
      case .failure(let error):
        self?.updateDebugConsoleOutput(with: "Failed to modify config.json: \(error.localizedDescription)")
      }
    }
  }
  
  func restoreLaunchBrowserInConfigJson() {
    guard let configManager = self.configManager, let originalLine = self.originalLaunchBrowserLine else {
      updateDebugConsoleOutput(with: "Error: Pre-conditions not met for restoring config.json.")
      return
    }
    
    configManager.restoreLaunchBrowser(originalLine: originalLine) { [weak self] result in
      switch result {
      case .success():
        self?.updateDebugConsoleOutput(with: "[config.json] << \(originalLine)")
        self?.updateDebugConsoleOutput(with: "[config.json] successfully restored")
      case .failure(let error):
        self?.updateDebugConsoleOutput(with: "Failed to restore config.json: \(error.localizedDescription)")
      }
    }
  }
  
  func parseServiceUrl(from output: String) {
    if serviceUrl == nil, output.contains("Running on local URL") {
      let pattern = "Running on local URL: \\s*(http://127\\.0\\.0\\.1:\\d+)"
      do {
        let regex = try NSRegularExpression(pattern: pattern)
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
