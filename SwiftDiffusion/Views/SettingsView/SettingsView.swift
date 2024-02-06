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
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          
          Text("Settings")
            .font(.largeTitle)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 14)
          
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
          .padding(.bottom, 14)
          
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
      }
      HStack {
        Spacer()
        Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
      }
    }
    .padding(14)
    .navigationTitle("Settings")
    .frame(minWidth: 500, idealWidth: 670)
    .frame(minHeight: 350, idealHeight: 500)
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
