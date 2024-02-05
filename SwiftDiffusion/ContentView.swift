//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI
import UniformTypeIdentifiers

extension Constants {
  static let horizontalPadding = CGFloat(8)
}

struct ContentView: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @State private var scriptPathInput: String = ""
  
  var body: some View {
    VStack {
      HStack {
        TextField("Path to webui.sh", text: $scriptPathInput)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button("Browse...") {
          browseFile()
        }
      }.padding(.horizontal, Constants.horizontalPadding)
      
      TextEditor(text: $scriptManager.consoleOutput)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.system(.body, design: .monospaced))
        .border(Color.gray.opacity(0.3), width: 1)
        .padding(.vertical, 10)
        .padding(.horizontal, Constants.horizontalPadding)
      
      HStack {
        Circle()
          .fill(scriptManager.scriptState.statusColor)
          .frame(width: 10, height: 10)
          .padding(.trailing, 2)
        
        Text(scriptManager.scriptStateText)
          .font(.system(.body, design: .monospaced))
          .onAppear {
            scriptPathInput = scriptManager.scriptPath ?? ""
            print("Current script state: \(scriptManager.scriptStateText)")
          }
        
        if scriptManager.scriptState.isActive, let url = scriptManager.parsedURL {
          Button(action: {
            NSWorkspace.shared.open(url)
          }) {
            Image(systemName: "network")
          }
          .buttonStyle(.plain)
          .padding(.leading, 2)
        }
        
        Spacer()
        
        Button(action: {
          scriptManager.terminatePythonProcesses {
            print("All Python processes terminated.")
          }
        }) {
          Image(systemName: "xmark.octagon")
        }
        .buttonStyle(.plain)
        .padding(.leading, 2)
        
        Button("Terminate") {
          ScriptManager.shared.terminateScript { result in
            switch result {
            case .success(let message):
              print(message)
            case .failure(let error):
              print("Error: \(error.localizedDescription)")
            }
          }
        }
        .disabled(!scriptManager.scriptState.isTerminatable)
        
        Button("Start") {
          scriptManager.scriptPath = scriptPathInput
          scriptManager.runScript()
        }
        .disabled(!scriptManager.scriptState.isStartable)
      }
      .padding(.horizontal, Constants.horizontalPadding)
    }
    .padding()
    .onAppear {
      scriptPathInput = scriptManager.scriptPath ?? ""
    }
    .navigationTitle("SwiftDiffusion")
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Button(action: {
          print("Toolbar item tapped")
        }) {
          Image(systemName: "gear")
        }
      }
    }
  }
  
  private func browseFile() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    
    if let shellScriptType = UTType(filenameExtension: "sh") {
      panel.allowedContentTypes = [shellScriptType]
    } else {
      print("Failed to find UTType for .sh files")
      return
    }
    
    panel.begin { (response) in
      if response == .OK, let url = panel.urls.first, url.pathExtension == "sh" {
        self.scriptPathInput = url.path
        self.scriptManager.scriptPath = url.path
      } else {
        print("Error: Selected file is not a .sh script.")
      }
    }
  }
}


#Preview {
  ContentView()
}
