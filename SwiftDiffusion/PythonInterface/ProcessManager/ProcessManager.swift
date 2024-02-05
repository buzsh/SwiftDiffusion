//
//  ProcessManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

extension Constants {
  struct CommandLine {
    static let zshPath = "/bin/zsh"
    static let zshUrl = URL(fileURLWithPath: zshPath)
  }
}

/// Manages execution of external processes.
class ProcessManager {
  private var process: Process?
  private var outputPipe: Pipe?
  private var errorPipe: Pipe?
  var outputHandler: ((String) -> Void)?
  
  /// Initializes a new ProcessManager.
  init() {}
  
  /// Sets up and starts a process with given script directory and name.
  /// - Parameters:
  ///   - scriptDirectory: The directory where the script is located.
  ///   - scriptName: The name of the script to be executed.
  func setupAndStartProcess(withScriptDirectory scriptDirectory: String, scriptName: String) {
    process = Process()
    outputPipe = Pipe()
    errorPipe = Pipe()
    
    process?.executableURL = Constants.CommandLine.zshUrl
    process?.arguments = ["-c", "cd \(scriptDirectory); ./\(scriptName)"]
    process?.standardOutput = outputPipe
    process?.standardError = errorPipe
    
    setupOutputHandlers()
    
    do {
      try process?.run()
    } catch {
      DispatchQueue.main.async {
        self.outputHandler?("Failed to start script: \(error.localizedDescription)")
      }
    }
  }
  
  /// Sets up handlers for process output and error streams.
  private func setupOutputHandlers() {
    let handler: (FileHandle) -> Void = { [weak self] fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
      DispatchQueue.main.async {
        self?.outputHandler?(output)
      }
    }
    
    outputPipe?.fileHandleForReading.readabilityHandler = handler
    errorPipe?.fileHandleForReading.readabilityHandler = handler
  }
}
