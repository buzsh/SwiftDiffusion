//
//  ConsoleView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

struct ConsoleView: View {
  @ObservedObject var scriptManager: ScriptManager
  @Binding var scriptPathInput: String
  
  var body: some View {
    VStack {
      HStack {
        TextField("Path to webui.sh", text: $scriptPathInput)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button("Browse...") {
          browseForWebuiShell()
        }
      }
      .padding(.horizontal, Constants.Layout.verticalPadding)
      
      TextEditor(text: $scriptManager.consoleOutput)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.system(.body, design: .monospaced))
        .border(Color.gray.opacity(0.3), width: 1)
        .padding(.vertical, 10)
        .padding(.horizontal, Constants.Layout.verticalPadding)
      
      HStack {
        Circle()
          .fill(scriptManager.scriptState.statusColor)
          .frame(width: 10, height: 10)
          .padding(.trailing, 2)
        
        Text(scriptManager.scriptStateText)
          .font(.system(.body, design: .monospaced))
          .onAppear {
            scriptPathInput = scriptManager.scriptPath ?? ""
            Debug.log("Current script state: \(scriptManager.scriptStateText)")
          }
        
        if scriptManager.scriptState.isActive, let url = scriptManager.serviceUrl {
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
          scriptManager.terminateAllPythonProcesses {
            Debug.log("All Python processes terminated.")
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
              Debug.log(message)
            case .failure(let error):
              Debug.log("Error: \(error.localizedDescription)")
            }
          }
        }
        .disabled(!scriptManager.scriptState.isTerminatable)
        
        Button("Start") {
          scriptManager.scriptPath = scriptPathInput
          scriptManager.run()
        }
        .disabled(!scriptManager.scriptState.isStartable)
      }
      .padding(.horizontal, Constants.Layout.verticalPadding)
    }
  }
    
  /// Allows the user to browse for `webui.sh` and sets the associated path variables
  func browseForWebuiShell() {
    Task {
      if let path = await FilePickerService.browseForShellFile() {
        self.scriptPathInput = path
        self.scriptManager.scriptPath = path
      }
    }
  }
}

/*
#Preview {
  ConsoleView(scriptManager: <#ScriptManager#>, scriptPathInput: <#Binding<String>#>)
}
*/
