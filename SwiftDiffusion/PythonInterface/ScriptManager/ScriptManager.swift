//
//  ScriptManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation

enum ScriptResult {
  case success(String) // Capture success message if needed
  case failure(Error)
}

class ScriptManager: ObservableObject {
  static let shared = ScriptManager()
  private var process: Process?
  private var outputPipe: Pipe?
  private var errorPipe: Pipe?
  
  @Published var consoleOutput: String = ""
  var scriptPath: String? {
    didSet {
      UserDefaults.standard.set(scriptPath, forKey: "scriptPath")
    }
  }
  
  init() {
    self.scriptPath = UserDefaults.standard.string(forKey: "scriptPath")
  }
  
  func runScript() {
    guard let scriptPath = scriptPath, !scriptPath.isEmpty else { return }
    let scriptDirectory = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path
    let scriptName = URL(fileURLWithPath: scriptPath).lastPathComponent
    
    process = Process()
    let pipe = Pipe()
    
    process?.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process?.arguments = ["-c", "cd \(scriptDirectory); ./\(scriptName)"]
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
    
    process.terminationHandler = { [weak self] _ in
      guard let self = self else { return }
      
      // Assuming successful termination if exit code is 0
      if process.terminationStatus == 0 {
        // Optionally parse self.consoleOutput for a success message
        completion(.success("Script terminated successfully."))
      } else {
        // Handle error scenario, potentially parsing self.consoleOutput for error details
        completion(.failure(NSError(domain: "ScriptManagerError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Script terminated with errors."])))
      }

      self.clearPipeHandlers()
    }
    
    process.terminate()
  }
  
  private func clearPipeHandlers() {
    outputPipe?.fileHandleForReading.readabilityHandler = nil
    errorPipe?.fileHandleForReading.readabilityHandler = nil
    process = nil
    outputPipe = nil
    errorPipe = nil
  }
}
