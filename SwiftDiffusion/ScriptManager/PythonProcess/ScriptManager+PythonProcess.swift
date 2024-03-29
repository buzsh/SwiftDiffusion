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
    
    guard userSettings.webuiShellPath.isEmpty || userSettings.stableDiffusionModelsPath.isEmpty else {
      updateScriptState(.unableToLocateScript)
      return
    }
    
    if let (scriptDirectory, scriptName) = ScriptSetupHelper.setupScriptPath(userSettings.webuiShellPath) {
      pythonProcess.runScript(at: scriptDirectory, scriptName: scriptName)
    }
  }
  
  func pythonProcessDidUpdateOutput(output: String) {
    let filteredOutput = shouldTrimOutput ? output.trimmingCharacters(in: .whitespacesAndNewlines) : output
    DispatchQueue.main.async {
      self.consoleOutput += "\n\(filteredOutput)"
      self.detectExistingPythonProcesses(from: filteredOutput)
      self.parseServiceUrl(from: filteredOutput)
      self.updateProgressBasedOnOutput(output: output)
      self.updateModelLoadStateBasedOnOutput(output: output)
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
