//
//  SettingsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct SettingsView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  
  @Binding var scriptPathInput: String
  @Environment(\.presentationMode) var presentationMode
  @AppStorage("showAllDescriptions") var showAllDescriptions: Bool = false
  
  var body: some View {
    VStack {
      ScrollView {
        VStack {
          VStack(alignment: .leading) {
            HStack {
              Text("Settings")
                .font(.largeTitle)
                .padding(.vertical, 20)
                .padding(.horizontal, 14)
              Spacer()
              Button(action: {
                showAllDescriptions.toggle()
              }) {
                Text(showAllDescriptions ? "Hide All" : "Show All")
                Image(systemName: "questionmark.circle")
              }
            }
            
            BrowseFileRow(labelText: "webui.sh file",
                          placeholderText: "../stable-diffusion-webui/webui.sh",
                          textValue: $scriptPathInput) {
              await FilePickerService.browseForShellFile()
            }
            
            BrowseFileRow(labelText: "Stable diffusion models",
                          placeholderText: "../stable-diffusion-webui/models/Stable-diffusion/",
                          textValue: $userSettings.stableDiffusionModelsPath) {
              await FilePickerService.browseForDirectory()
            }
            
            BrowseFileRow(labelText: "Custom image output directory",
                          placeholderText: "~/Documents/SwiftDiffusion/",
                          textValue: $userSettings.outputDirectoryPath) {
              await FilePickerService.browseForDirectory()
            }
            
          }
          .onChange(of: userSettings.stableDiffusionModelsPath) {
            Task {
              await modelManagerViewModel.loadModels()
            }
          }
          
          VStack(alignment: .leading) {
            Text("Prompt")
              .font(.title)
              .padding(.vertical, 20)
              .padding(.horizontal, 14)
            VStack(alignment: .leading) {
              ToggleWithHeader(isToggled: $userSettings.alwaysStartPythonEnvironmentAtLaunch, header: "Start Python environment at launch", description: "This will automatically ready the Python environment such that you can start generating immediately.", showAllDescriptions: showAllDescriptions)
              
              ToggleWithHeader(isToggled: $userSettings.disablePasteboardParsingForGenerationData, header: "Disable automatic generation data parsing", description: "When you copy generation data from sites like Civit.ai, this will automatically format it and show a button to paste it.", showAllDescriptions: showAllDescriptions)
              
              ToggleWithHeader(isToggled: $userSettings.alwaysShowPasteboardGenerationDataButton, header: "Always show Paste Generation Data button", description: "This will cause the 'Paste Generation Data' button to always show, even if copied data is incompatible and cannot be pasted.", showAllDescriptions: showAllDescriptions)
              
              ToggleWithHeader(isToggled: $userSettings.disableModelLoadingRamOptimizations, header: "Disable model loading RAM optimizations", description: "Can sometimes resolve certain model load issues regarding MPS, BFloat16. Warning: Can increase load times significantly.", showAllDescriptions: showAllDescriptions)
            }
            .padding(.leading, 8)
            
            Text("Developer")
              .font(.title)
              .padding(.vertical, 20)
              .padding(.horizontal, 14)
            
            ToggleWithHeader(isToggled: $userSettings.showDebugMenu, header: "Show Debug menu", description: "This will show the Debug menu in the top menu bar.", showAllDescriptions: showAllDescriptions)
            
            ToggleWithHeader(isToggled: $userSettings.killAllPythonProcessesOnTerminate, header: "Kill all Python processes on terminate", description: "Will terminate all Python processes on terminate. Useful for Xcode development force stopping.", showAllDescriptions: showAllDescriptions)
          }
          
          
        }
        .padding(.horizontal, 16)
      }//scrollview
      VStack {
        HStack {
          Button("Restore Defaults") {
            userSettings.restoreDefaults()
          }
          Spacer()
          Button("Done") {
            presentationMode.wrappedValue.dismiss()
          }
        }
        
        .padding(10)
      }
      .background(Color(NSColor.windowBackgroundColor))
    }
    .padding(2)
    .navigationTitle("Settings")
    .frame(minWidth: 500, idealWidth: 670, minHeight: 350, idealHeight: 700)
  }
}

#Preview {
  SettingsView(scriptPathInput: .constant(""))
    .frame(width: 500, height: 400)
}

struct ToggleWithHeader: View {
  @Binding var isToggled: Bool
  var header: String
  var description: String = ""
  @State private var isHovering = false
  var showAllDescriptions: Bool
  
  var body: some View {
    HStack(alignment: .top) {
      Toggle("", isOn: $isToggled)
        .padding(.trailing, 6)
        .padding(.top, 2)
      
      VStack(alignment: .leading) {
        HStack {
          Text(header)
            .font(.system(size: 14, weight: .semibold, design: .default))
            .underline()
            .padding(.vertical, 2)
          Image(systemName: "questionmark.circle")
            .onHover { isHovering in
              self.isHovering = isHovering
            }
        }
        Text(description)
          .font(.system(size: 12))
          .foregroundStyle(Color.secondary)
          .opacity(showAllDescriptions || isHovering ? 1 : 0)
      }
      
    }
    .padding(.bottom, 8)
  }
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
          .font(.system(size: 14, weight: .semibold, design: .default))
          .underline()
          .padding(.vertical, 2)
          .padding(.horizontal, 14)
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
