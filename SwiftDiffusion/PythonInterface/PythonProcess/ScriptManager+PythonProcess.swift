//
//  ScriptManager+PythonProcess.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

extension ScriptManager: PythonProcessDelegate {
  func setupPythonProcess() {
    let pythonProcess = PythonProcess()
    pythonProcess.delegate = self
    if let (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(scriptPath) {
      pythonProcess.runScript(at: scriptDirectory, scriptName: scriptName)
    }
  }
  
  func pythonProcessDidUpdateOutput(output: String) {
    let filteredOutput = shouldTrimOutput ? output.trimmingCharacters(in: .whitespacesAndNewlines) : output
    DispatchQueue.main.async {
      self.consoleOutput += "\n\(filteredOutput)"
      self.parseServiceUrl(from: filteredOutput)
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
