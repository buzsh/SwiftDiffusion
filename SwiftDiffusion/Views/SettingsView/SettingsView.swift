//
//  SettingsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct SettingsView: View {
  @Binding var scriptPathInput: String
  @Binding var fileOutputDir: String
  
  var body: some View {
    VStack(alignment: .leading) {
      
      Text("webui.sh path")
        .padding(.horizontal, 14)
        .font(.system(.body, design: .monospaced))
      
      HStack {
        TextField("path/to/webui.sh", text: $scriptPathInput)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button("Browse...") {
          browseForWebuiShell()
        }
      }
      
      Text("image output directory")
        .padding(.horizontal, 14)
        .font(.system(.body, design: .monospaced))
      
      HStack {
        TextField("path/to/outputs", text: $fileOutputDir)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button("Browse...") {
          browseForOutputDirectory()
        }
      }
      Spacer()
    }
    .padding(14)
  }
  
  /// Allows the user to browse for `webui.sh` and sets the associated path variables
  func browseForWebuiShell() {
    Task {
      if let path = await FilePickerService.browseForShellFile() {
        self.scriptPathInput = path
      }
    }
  }
  
  func browseForOutputDirectory() {
    Task {
      if let path = await FilePickerService.browseForDirectory() {
        self.fileOutputDir = path
      }
    }
  }
}

#Preview {
  SettingsView(scriptPathInput: .constant("path/to/webui.sh"), fileOutputDir: .constant("path/to/outputs/"))
}
