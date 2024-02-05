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

class ScriptManager: ObservableObject, PythonProcessDelegate {
  static let shared = ScriptManager()
  private var pythonProcess: PythonProcess?
  
  private(set) var serviceURL: URL?
  @Published var parsedURL: URL? = nil
  
  private let configManager: ConfigFileManager?
  private var originalLaunchBrowserLine: String?
  
  var shouldTrimOutput: Bool = false
  
  @Published var scriptState: ScriptState = .readyToStart
  @Published var consoleOutput: String = ""
  var scriptPath: String? {
    didSet {
      UserDefaults.standard.set(scriptPath, forKey: "scriptPath")
    }
  }
  /// Initializes a new instance of `ScriptManager`.
  init() {
    self.scriptPath = UserDefaults.standard.string(forKey: "scriptPath")
    if let scriptPath = self.scriptPath {
      self.configManager = ConfigFileManager(scriptPath: scriptPath)
    } else {
      self.configManager = nil
    }
  }
  
  func updateScriptState(_ state: ScriptState) {
    scriptState = state
    
    if state == .terminated {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.scriptState = .readyToStart
      }
    }
  }
  
  /// Updates the console output with a new message.
  /// - Parameter message: The message to be added to the console output.
  private func updateConsoleOutput(with message: String) {
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
    serviceURL = nil
    parsedURL = nil
  }
  
  func runScript() {
    newRunScriptState()
    guard let (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(scriptPath) else { return }
    
    disableLaunchBrowserInConfigJson()
    
    pythonProcess = PythonProcess() // Initialize PythonProcess
    pythonProcess?.delegate = self
    pythonProcess?.runScript(at: scriptDirectory, scriptName: scriptName)
  }
  
  
  /// Terminates the script execution.
  /// - Parameter completion: A closure that is called with the result of the termination attempt.
  func terminateScript(completion: @escaping (ScriptResult) -> Void) {
    updateScriptState(.isTerminating)
    pythonProcess?.terminate()
    // No need for the async block used previously, as termination logic is now encapsulated within PythonProcess
    
    // Handle post-termination logic here
    restoreLaunchBrowserInConfigJson()
    completion(.success("Script terminated successfully."))
    
    updateScriptState(.terminated)
  }
  
  /// Terminates the script execution immediately.
  func terminateImmediately() {
    pythonProcess?.terminate() // Terminate the script using PythonProcess
    restoreLaunchBrowserInConfigJson() // Restore any configurations if needed
    
    // Since the termination logic is encapsulated, no need to clear handlers here
    DispatchQueue.main.async {
      self.updateScriptState(.terminated)
    }
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
  
  private func parseForServiceURL(from output: String) {
    if serviceURL == nil, output.contains("Running on local URL") {
      let pattern = "Running on local URL: \\s*(http://127\\.0\\.0\\.1:\\d+)"
      do {
        let regex = try NSRegularExpression(pattern: pattern)
        let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
        if let match = regex.firstMatch(in: output, options: [], range: nsRange) {
          let urlRange = Range(match.range(at: 1), in: output)!
          let url = String(output[urlRange])
          self.parsedURL = URL(string: url)
          DispatchQueue.main.async {
            self.updateScriptState(.active(url)) //self.scriptState = .active(url)
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
  
  // MARK: - PythonProcessDelegate methods
  
  func setupPythonProcess() {
    let pythonProcess = PythonProcess()
    pythonProcess.delegate = self
    // Assuming you have a method or property to determine the script path and name
    if let (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(scriptPath) {
      pythonProcess.runScript(at: scriptDirectory, scriptName: scriptName)
    }
  }
  
  func pythonProcessDidUpdateOutput(output: String) {
    let filteredOutput = shouldTrimOutput ? output.trimmingCharacters(in: .whitespacesAndNewlines) : output
    DispatchQueue.main.async {
      self.consoleOutput += "\n\(filteredOutput)"
      self.parseForServiceURL(from: filteredOutput)
    }
  }
  
  func pythonProcessDidFinishRunning(with result: ScriptResult) {
    switch result {
    case .success(let message):
      DispatchQueue.main.async {
        self.updateScriptState(.terminated)
        self.updateConsoleOutput(with: message)
      }
    case .failure(let error):
      DispatchQueue.main.async {
        self.updateConsoleOutput(with: "Script failed: \(error.localizedDescription)")
        self.updateScriptState(.readyToStart)
      }
    }
  }
  
  
}


extension ScriptManager {
  
  func checkScriptServiceAvailability(completion: @escaping (Bool) -> Void) {
    guard let url = serviceURL else {
      Debug.log("Service URL not available.")
      completion(false)
      return
    }
    
    let task = URLSession.shared.dataTask(with: url) { _, response, error in
      DispatchQueue.main.async {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
          // page loaded successfully, script is likely still running
          completion(true)
        } else {
          // request failed, script is likely terminated
          completion(false)
        }
      }
    }
    
    task.resume()
  }
}


extension ScriptManager {
  /// Terminates all running Python processes.
  /// - Parameter completion: An optional closure to call after the operation completes.
  func terminatePythonProcesses(completion: (() -> Void)? = nil) {
    terminateImmediately()
    
    let process = Process()
    let pipe = Pipe()
    
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", "killall Python"]
    
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
      try process.run()
      process.waitUntilExit() // wait for process to exit
      
      // read and log the output
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      DispatchQueue.main.async {
        Debug.log("Terminate Python Output: \(output)")
        self.updateConsoleOutput(with: "All Python-related processes have been killed.")
        completion?()
      }
    } catch {
      DispatchQueue.main.async {
        Debug.log("Failed to terminate Python processes: \(error)")
        completion?()
      }
    }
  }
}
