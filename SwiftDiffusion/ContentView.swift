//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

struct ContentView: View {
  @State private var scriptPath = ""
  @State private var consoleOutput = ""
  @State private var process: Process?
  @State private var outputPipe: Pipe?
  @State private var errorPipe: Pipe?
  
  var body: some View {
    VStack {
      HStack {
        TextField("Path to webui.sh", text: $scriptPath)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Button("Browse...") {
          browseFile()
        }
      }.padding()
      
      TextEditor(text: $consoleOutput)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.system(.body, design: .monospaced))
        .border(Color.gray, width: 1)
        .padding()
      
      HStack {
        Button("Stop") {
          stopScript()
        }
        Button("Start") {
          runScript()
        }
      }.padding()
    }
    .padding()
    /*
    .onChange(of: consoleOutput) { _ in
      scrollToBottom()
    }
     */
  }
  
  private func browseFile() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.allowedFileTypes = ["sh"]
    panel.begin { (response) in
      if response == .OK {
        if let url = panel.urls.first {
          self.scriptPath = url.path
        }
      }
    }
  }
  
  private func runScript() {
    guard !scriptPath.isEmpty else { return }
    let scriptDirectory = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path
    let scriptName = URL(fileURLWithPath: scriptPath).lastPathComponent
    
    let process = Process()
    let pipe = Pipe()
    
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    // cd to webui.sh script directory before executing it
    // A1111 will check for dependencies in execution origin
    process.arguments = ["-c", "cd \(scriptDirectory); ./\(scriptName)"]
    process.standardOutput = pipe
    process.standardError = pipe
    
    pipe.fileHandleForReading.readabilityHandler = { fileHandle in
      if let output = String(data: fileHandle.availableData, encoding: .utf8) {
        DispatchQueue.main.async {
          self.consoleOutput += output
        }
      }
    }
    
    do {
      try process.run()
      self.process = process
    } catch {
      consoleOutput += "Failed to start script: \(error.localizedDescription)"
    }
  }
  
  private func stopScript() {
    guard let process = process else { return }

    process.terminate()
    
    // Safely clear the pipe's readabilityHandler to prevent hanging
    clearPipeHandlers()
    
    DispatchQueue.main.async {
      // Append console terminated message
      self.consoleOutput += "\nProcess terminated."
    }
  }
  
  private func clearPipeHandlers() {
    outputPipe?.fileHandleForReading.readabilityHandler = nil
    errorPipe?.fileHandleForReading.readabilityHandler = nil
    self.process = nil
    self.outputPipe = nil
    self.errorPipe = nil
  }
  
  private func handleError(_ error: Error) {
    DispatchQueue.main.async {
      self.consoleOutput += "\nError: \(error.localizedDescription)"
    }
  }
}

#Preview {
  ContentView()
}
