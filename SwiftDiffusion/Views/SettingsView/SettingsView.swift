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
            .padding(.vertical, 20)
            .padding(.horizontal, 14)
          
          BrowseFileRow(labelText: "webui.sh path",
                        placeholderText: "path/to/webui.sh",
                        textValue: $scriptPathInput) {
            await FilePickerService.browseForShellFile()
          }
          
          BrowseFileRow(labelText: "image output directory",
                        placeholderText: "path/to/outputs",
                        textValue: $fileOutputDir) {
            await FilePickerService.browseForDirectory()
          }
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
    .frame(minWidth: 500, idealWidth: 670, minHeight: 350, idealHeight: 500)
  }
}

#Preview {
  SettingsView(scriptPathInput: .constant("path/to/webui.sh"), fileOutputDir: .constant("path/to/outputs/"))
}

struct BrowseFileRow: View {
  var labelText: String?
  var placeholderText: String
  @Binding var textValue: String
  var browseAction: () async -> String?
  
  var body: some View {
    VStack(alignment: .leading) {
      if let label = labelText {
        Text(label)
          .padding(.horizontal, 14)
          .font(.system(.body, design: .monospaced))
      }
      HStack {
        TextField(placeholderText, text: $textValue)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button("Browse...") {
          Task {
            if let path = await browseAction() {
              textValue = path
            }
          }
        }
      }
      .padding(.bottom, 14)
    }
  }
}
