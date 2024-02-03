//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

extension ScriptState {
  var statusColor: Color {
    switch self {
    case .readyToStart: return Color.gray
    case .launching: return Color.yellow
    case .active(_): return Color.green
    case .isTerminating: return Color.yellow
    case .terminated: return Color.red
    }
  }
  var isActive: Bool {
    if case .active(_) = self {
      return true
    } else {
      return false
    }
  }
}

struct ContentView: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @State private var scriptPathInput: String = ""
  
  var body: some View {
    VStack {
      HStack {
        TextField("Path to webui.sh", text: $scriptPathInput)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Button("Browse...") {
          browseFile()
        }
      }.padding()
      
      TextEditor(text: $scriptManager.consoleOutput)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.system(.body, design: .monospaced))
        .border(Color.gray, width: 1)
        .padding()
      
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
            Image(systemName: "globe")
          }
          .buttonStyle(.plain)
          .padding(.leading, 2)
        }
        
        Spacer()
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
        Button("Start") {
          scriptManager.scriptPath = scriptPathInput
          scriptManager.runScript()
        }
      }.padding()
    }
    .padding()
    .onAppear {
      scriptPathInput = scriptManager.scriptPath ?? ""
    }
  }
  
  private func browseFile() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.allowedFileTypes = ["sh"]
    panel.begin { (response) in
      if response == .OK {
        if let url = panel.urls.first {
          // Update the script path in the UI and scriptManager
          self.scriptPathInput = url.path
          self.scriptManager.scriptPath = url.path
        }
      }
    }
  }
}


#Preview {
  ContentView()
}
