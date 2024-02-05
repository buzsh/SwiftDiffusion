//
//  ScriptManager+TerminateAll.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

extension Constants.CommandLine {
  static let killallPython = "killall Python"
}

extension ScriptManager {
  /// Terminates all running Python processes.
  /// - Parameter completion: An optional closure to call after the operation completes.
  func terminateAllPythonProcesses(completion: (() -> Void)? = nil) {
    let process = Process()
    let pipe = Pipe()
    
    process.executableURL = Constants.CommandLine.zshUrl
    process.arguments = ["-c", Constants.CommandLine.killallPython]
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
        self.terminateImmediately()
      }
    } catch {
      DispatchQueue.main.async {
        Debug.log("Failed to terminate Python processes: \(error)")
        completion?()
      }
    }
  }
}
