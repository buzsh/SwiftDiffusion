//
//  ScriptManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation

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
  
  func terminateScript() {
    process?.terminate()
    clearPipeHandlers()
    DispatchQueue.main.async { [weak self] in
      self?.consoleOutput += "\nProcess terminated."
    }
  }
  
  private func clearPipeHandlers() {
    outputPipe?.fileHandleForReading.readabilityHandler = nil
    errorPipe?.fileHandleForReading.readabilityHandler = nil
    process = nil
    outputPipe = nil
    errorPipe = nil
  }
}
