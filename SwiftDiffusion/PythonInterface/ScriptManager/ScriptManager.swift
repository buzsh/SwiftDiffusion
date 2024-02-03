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
  
  private let configManager: ConfigFileManager?
  private var originalLaunchBrowserLine: String?
  
  @Published var consoleOutput: String = ""
  var scriptPath: String? {
    didSet {
      UserDefaults.standard.set(scriptPath, forKey: "scriptPath")
    }
  }
  
  init() {
    self.scriptPath = UserDefaults.standard.string(forKey: "scriptPath")
    if let scriptPath = self.scriptPath {
      self.configManager = ConfigFileManager(scriptPath: scriptPath)
    } else {
      self.configManager = nil
    }
  }
  
  func runScript() {
    guard let scriptPath = scriptPath, !scriptPath.isEmpty else { return }
    let scriptDirectory = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path
    let scriptName = URL(fileURLWithPath: scriptPath).lastPathComponent
    
    process = Process()
    let pipe = Pipe()
    
    // find config.json, change line `auto_launch_browser": "Local",` to `auto_launch_browser": "Disable",`
    
    process?.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process?.arguments = ["-c", "cd \(scriptDirectory); ./\(scriptName) --autolaunch"]
    process?.standardOutput = pipe
    process?.standardError = pipe
    
    pipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
      if let output = String(data: fileHandle.availableData, encoding: .utf8) {
        DispatchQueue.main.async {
          self?.consoleOutput += output
        }
      }
    }
    
    do {
      try process?.run()
    } catch {
      consoleOutput += "Failed to start script: \(error.localizedDescription)"
    }
  }
  
  func terminateScript(completion: @escaping (ScriptResult) -> Void) {
    guard let process = process else {
      completion(.failure(NSError(domain: "ScriptManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Process not running."])))
      return
    }
    
    // Set the termination handler
    process.terminationHandler = { [weak self] process in
      // Ensure we capture any final output
      let outputData = self?.outputPipe?.fileHandleForReading.availableData
      if let output = String(data: outputData ?? Data(), encoding: .utf8), !output.isEmpty {
        DispatchQueue.main.async {
          self?.consoleOutput += output
        }
      }
      
      DispatchQueue.main.async {
        if process.terminationStatus == 0 {
          completion(.success("Script terminated successfully."))
        } else {
          completion(.failure(NSError(domain: "ScriptManagerError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Script terminated with errors."])))
        }
        // Clear handlers and pipes after capturing final output
        self?.clearPipeHandlers()
      }
    }
    
    // Terminate the process
    process.terminate()
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
      consoleOutput += "\nError: ConfigFileManager is not initialized."
      return
    }
    
    configManager.disableLaunchBrowser { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let originalLine):
          self?.originalLaunchBrowserLine = originalLine
          self?.consoleOutput += "\nBrowser launch disabled in config.json."
        case .failure(let error):
          self?.consoleOutput += "\nFailed to modify config.json: \(error.localizedDescription)"
        }
      }
    }
  }
  
  func restoreLaunchBrowserInConfigJson() {
    guard let configManager = self.configManager, let originalLine = self.originalLaunchBrowserLine else {
      consoleOutput += "\nError: Pre-conditions not met for restoring config.json."
      return
    }
    
    configManager.restoreLaunchBrowser(originalLine: originalLine) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success():
          self?.consoleOutput += "\nBrowser launch setting restored in config.json."
        case .failure(let error):
          self?.consoleOutput += "\nFailed to restore config.json: \(error.localizedDescription)"
        }
      }
    }
  }
  
}
