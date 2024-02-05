//
//  PythonProcess.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

extension Constants.CommandLine {
  static var defaultCommand: (String, String) -> String = { dir, name in
      return "cd \(dir); ./\(name)"
  }
}

protocol PythonProcessDelegate: AnyObject {
  func pythonProcessDidUpdateOutput(output: String)
  func pythonProcessDidFinishRunning(with result: ScriptResult)
}

/// Manages execution of external Python processes.
class PythonProcess {
  private var process: Process?
  private var outputPipe: Pipe?
  private var errorPipe: Pipe?
  
  weak var delegate: PythonProcessDelegate?
  
  /// Initializes a new PythonProcess.
  init() { }
  
  /// Sets up and starts a process with given script directory, name and optional overriding arguments..
  /// - Parameters:
  ///   - scriptDirectory: The directory where the script is located.
  ///   - scriptName: The name of the script to be executed.
  ///   - arguments: Override with custom arguments.
  ///
  /// - important: If overriding default arguments, you must include: `cd \(scriptDirectory); ./\(scriptName)`
  func runScript(at path: String, scriptName: String, arguments: [String] = []) {
    let process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    
    self.process = process
    self.outputPipe = outputPipe
    self.errorPipe = errorPipe
    
    process.executableURL = Constants.CommandLine.zshUrl
    let scriptDirectory = path
    let command = arguments.isEmpty ? Constants.CommandLine.defaultCommand(scriptDirectory, scriptName) : arguments.joined(separator: " ")
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
  
  /// Sets up handlers for process output and error streams.
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
  
  /// Terminate the PythonProcess.
  func terminate() {
    process?.terminate()
    clearProcessAndPipes()
  }
  
  private func clearProcessAndPipes() {
    outputPipe?.fileHandleForReading.readabilityHandler = nil
    errorPipe?.fileHandleForReading.readabilityHandler = nil
    process = nil
    outputPipe = nil
    errorPipe = nil
  }
  
  deinit {
    clearProcessAndPipes()
  }
  
}
