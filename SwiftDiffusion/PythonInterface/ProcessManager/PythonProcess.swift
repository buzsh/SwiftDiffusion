//
//  PythonProcess.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

protocol PythonProcessDelegate: AnyObject {
  func pythonProcessDidUpdateOutput(output: String)
  func pythonProcessDidFinishRunning(with result: ScriptResult)
}

class PythonProcess {
  private var process: Process?
  private var outputPipe: Pipe?
  private var errorPipe: Pipe?
  
  weak var delegate: PythonProcessDelegate?
  
  init() { }
  
  func runScript(at path: String, scriptName: String, arguments: [String] = []) {
    let process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    
    self.process = process
    self.outputPipe = outputPipe
    self.errorPipe = errorPipe
    
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    let scriptDirectory = path
    let command = arguments.isEmpty ? "cd \(scriptDirectory); ./\(scriptName)" : arguments.joined(separator: " ")
    process.arguments = ["-c", command]
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    setupOutputHandling()
    
    do {
      try process.run()
    } catch {
      delegate?.pythonProcessDidFinishRunning(with: .failure(error))
    }
  }
  
  private func setupOutputHandling() {
    outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
      self?.delegate?.pythonProcessDidUpdateOutput(output: output)
    }
    
    errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
      self?.delegate?.pythonProcessDidUpdateOutput(output: output)
    }
    
    process?.terminationHandler = { [weak self] _ in
      self?.delegate?.pythonProcessDidFinishRunning(with: .success("Script finished running"))
    }
  }
  
  func terminate() {
    process?.terminate()
  }
  
}
