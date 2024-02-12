//
//  SettingsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

extension Constants.WindowSize {
  struct Settings {
    static let defaultWidth: CGFloat = 670
    static let defaultHeight: CGFloat = 700
  }
}

// Define the sections
enum SettingsTab: String, CaseIterable, Identifiable {
  case general = "General"
  case files = "Files"
  case prompt = "Prompt"
  case developer = "Developer"
  
  var id: Self { self }
  
  // Provide an associated system image name for each tab
  var systemImageName: String {
    switch self {
    case .general: return "gearshape"
    case .files: return "doc.on.doc"
    case .prompt: return "text.bubble"
    case .developer: return "hammer"
    }
  }
}

struct ToolbarButtonStyle: ButtonStyle {
  var isSelected: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(isSelected ? Color.accentColor : Color.primary)
      .padding(4)
      .frame(minWidth: 56) // Specify the minimum width here
      .background(self.isSelected ? Color.gray.opacity(0.2) : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

struct SettingsView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  
  @Environment(\.presentationMode) var presentationMode
  @AppStorage("showAllDescriptions") var showAllDescriptions: Bool = false
  
  @State private var selectedTab: SettingsTab = .general
  
  var body: some View {
    VStack(spacing: 0) {
      Picker("", selection: $selectedTab) {
        ForEach(SettingsTab.allCases) { tab in
          Text(tab.rawValue).tag(tab)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()
      
      // Conditionally display the content based on the selected tab
      switch selectedTab {
      case .general:
        FilesSection(userSettings: userSettings)
      case .files:
        FilesSection(userSettings: userSettings)
      case .prompt:
        PromptSection(userSettings: userSettings)
      case .developer:
        DeveloperSection(userSettings: userSettings)
      }
      
      
      ScrollView {
        VStack {
          VStack(alignment: .leading) {
            
            BrowseFileRow(labelText: "webui.sh file",
                          placeholderText: "../stable-diffusion-webui/webui.sh",
                          textValue: $userSettings.webuiShellPath) {
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
          .padding(.top)
          .onChange(of: userSettings.stableDiffusionModelsPath) {
            Task {
              await modelManagerViewModel.loadModels()
            }
          }
          
          VStack(alignment: .leading) {
            HStack {
              Text("Prompt")
                .font(.title)
                .padding(.vertical, 20)
                .padding(.horizontal, 14)
              
              
              Spacer()
              Button(action: {
                showAllDescriptions.toggle()
              }) {
                HStack {
                  Text(showAllDescriptions ? "Hide Help" : "Show Help")
                }
                .padding(.horizontal, 2)
              }
            }
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
      }
      .frame(maxHeight: .infinity)
      //scrollview
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
          ForEach(SettingsTab.allCases, id: \.self) { tab in
            Button(action: {
              self.selectedTab = tab
            }) {
              VStack {
                Image(systemName: tab.systemImageName)
                  .padding(.bottom, 0.1)
                Text(tab.rawValue)
                  .font(.system(size: 10))
                  .fixedSize(horizontal: false, vertical: true) // Ensure text does not truncate
              }
            }
            .buttonStyle(ToolbarButtonStyle(isSelected: selectedTab == tab))
            
          }
          
          /*
          Button(action: {
            showAllDescriptions.toggle()
          }) {
            HStack {
              Text(showAllDescriptions ? "Hide Help" : "Show Help")
              //Image(systemName: "questionmark.circle")
            }
            .padding(.horizontal, 2)
          }
           */
          
        }
      }
    }
  }
}

#Preview {
  SettingsView()
    .frame(width: 600, height: 700)
}

struct GeneralSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    // Implement the UI for file settings
    Text("General settings here")
  }
}

struct FilesSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    // Implement the UI for file settings
    Text("Files settings here")
  }
}

struct PromptSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    // Implement the UI for prompt settings
    Text("Prompt settings here")
  }
}

struct DeveloperSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    // Implement the UI for developer settings
    Text("Developer settings here")
  }
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
          .font(.system(size: 11, design: .monospaced))
          .disabled(true)
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
