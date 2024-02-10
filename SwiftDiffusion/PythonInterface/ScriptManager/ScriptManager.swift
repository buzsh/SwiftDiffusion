//
//  ScriptManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation

enum ScriptResult {
  case success(String)
  case failure(Error)
}

extension Constants.Keys {
  static let scriptPath = "scriptPath"
}

extension Constants.Delays {
  static let secondsBetweenTerminatedAndReadyState: Double = 2
}

class ScriptManager: ObservableObject {
  static let shared = ScriptManager()
  private var pythonProcess: PythonProcess?
  
  @Published var serviceUrl: URL? = nil
  
  private let configManager: ConfigFileManager?
  private var originalLaunchBrowserLine: String?
  
  var shouldTrimOutput: Bool = false
  
  enum GenerationStatus { case idle, preparingToGenerate, generating, finishingUp, done }
  
  @Published var genStatus: GenerationStatus = .idle
  @Published var genProgress: Double = 0
  
  @Published var modelLoadState: ModelLoadState = .idle
  @Published var modelLoadTime: Double = 0

  @Published var scriptState: ScriptState = .readyToStart
  @Published var consoleOutput: String = ""
  var scriptPath: String? {
    didSet {
      UserDefaults.standard.set(scriptPath, forKey: Constants.Keys.scriptPath)
    }
  }
  /// Initializes a new instance of `ScriptManager`.
  init() {
    self.scriptPath = UserDefaults.standard.string(forKey: Constants.Keys.scriptPath)
    if let scriptPath = self.scriptPath {
      self.configManager = ConfigFileManager(scriptPath: scriptPath)
    } else {
      self.configManager = nil
    }
  }
  
  func updateScriptState(_ state: ScriptState) {
    self.scriptState = state
    
    if state == .terminated {
      Delay.by(Constants.Delays.secondsBetweenTerminatedAndReadyState) {
        self.scriptState = .readyToStart
      }
    }
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
    serviceUrl = nil
  }
  
  func run() {
    modelLoadState = .launching
    
    newRunScriptState()
    guard let (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(scriptPath) else { return }
    
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

      // Handle post-termination logic
      restoreLaunchBrowserInConfigJson()
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
            Debug.log("URL successfully parsed and state updated to active: \(url)")
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
