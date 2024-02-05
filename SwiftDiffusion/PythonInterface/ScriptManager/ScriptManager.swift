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

class ScriptManager: ObservableObject {
  static let shared = ScriptManager()
  private var process: Process?
  private var outputPipe: Pipe?
  private var errorPipe: Pipe?
  
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
  
  /// Starts the execution of the Automatic1111 Python script.
  func runScript() {
    Debug.log("Starting ./webui.sh")
    scriptState = .launching
    serviceURL = nil
    
    guard let scriptPath = scriptPath, !scriptPath.isEmpty else { return }
    let scriptDirectory = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path
    let scriptName = URL(fileURLWithPath: scriptPath).lastPathComponent
    
    process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    self.outputPipe = outputPipe
    self.errorPipe = errorPipe
    
    disableLaunchBrowserInConfigJson()  // not detrimental if fails, but stops webui from launching in browser on startup
    
    process?.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process?.arguments = ["-c", "cd \(scriptDirectory); ./\(scriptName)"]
    process?.standardOutput = outputPipe
    process?.standardError = errorPipe
    
    let outputHandler: (FileHandle) -> Void = { [weak self] fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty else { return }
      let output = String(data: data, encoding: .utf8) ?? ""
      
      let finalOutput = self?.shouldTrimOutput == true ? output.trimmingCharacters(in: .whitespacesAndNewlines) : output
      
      DispatchQueue.main.async {
        self?.consoleOutput += "\n\(finalOutput)"
        self?.parseForServiceURL(from: finalOutput)
      }
    }
    
    outputPipe.fileHandleForReading.readabilityHandler = outputHandler
    errorPipe.fileHandleForReading.readabilityHandler = outputHandler
    
    do {
      try process?.run()
    } catch {
      DispatchQueue.main.async {
        self.updateConsoleOutput(with: "Failed to start script: \(error.localizedDescription)")
      }
    }
  }
  
  /// Terminates the script execution.
  /// - Parameter completion: A closure that is called with the result of the termination attempt.
  func terminateScript(completion: @escaping (ScriptResult) -> Void) {
    self.scriptState = .isTerminating
    
    DispatchQueue.global(qos: .background).async {
      self.restoreLaunchBrowserInConfigJson()
      
      guard let process = self.process else {
        DispatchQueue.main.async {
          completion(.failure(NSError(domain: "ScriptManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No process is currently running."])))
        }
        return
      }
      
      process.terminate()
      self.clearPipeHandlers()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.checkScriptServiceAvailability { isRunning in
          if !isRunning {
            completion(.success("Script terminated successfully and the service is no longer accessible."))
            self.scriptState = .terminated
            self.parsedURL = nil
            self.updateConsoleOutput(with: "Service terminated.")
            // after 3s, change back to ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              self.scriptState = .readyToStart
            }
          } else {
            completion(.failure(NSError(domain: "ScriptManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "The script's web service is still accessible after attempting to terminate the script."])))
          }
        }
      }
    }
  }
  
  /// Terminates the script execution immediately.
  func terminateImmediately() {
    if let process = self.process, process.isRunning {
      process.terminate()
      restoreLaunchBrowserInConfigJson()
      clearPipeHandlers()
    }
    
    DispatchQueue.main.async {
      self.scriptState = .terminated
      self.parsedURL = nil
    }
  }
  
  private func clearPipeHandlers() {
    outputPipe?.fileHandleForReading.readabilityHandler = nil
    errorPipe?.fileHandleForReading.readabilityHandler = nil
    process = nil
    outputPipe = nil
    errorPipe = nil
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
            self.scriptState = .active(url)
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
