//
//  RequiredInputPathsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import SwiftUI

struct RequiredInputPathsView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @Environment(\.presentationMode) var presentationMode
  @State private var showBrowseShellRow = false
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          HStack {
            Text("Locate Automatic Folder")
              .font(.system(size: 20, weight: .semibold, design: .rounded))
              .padding(.vertical, 20)
              .padding(.horizontal, 14)
            Spacer()
          }
          
          Text("To enable interfacing with PyTorch through Automatic, please locate the stable-diffusion-webui folder.")
            .padding(.horizontal, 14)
            .padding(.bottom, 30)
          
          BrowseRequiredFileRow(labelText: "Automatic path directory",
                                placeholderText: "../stable-diffusion-webui/",
                                textValue: $userSettings.automaticDirectoryPath,
                                requiresEntry: true
          ){
            await FilePickerService.browseForDirectory()
          }
          .onChange(of: userSettings.automaticDirectoryPath) {
            userSettings.setDefaultPathsForEmptySettings()
            checkForShellFileAndAnimate()
          }
          .padding(.horizontal, 20)
          
          if showBrowseShellRow {
            BrowseRequiredFileRow(labelText: "webui.sh file",
                                  placeholderText: "../stable-diffusion-webui/webui.sh",
                                  textValue: $userSettings.webuiShellPath,
                                  requiresEntry: true
            ){
              await FilePickerService.browseForShellFile()
            }
            .opacity(showBrowseShellRow ? 1 : 0)
            .offset(y: showBrowseShellRow ? 0 : -50)
            .animation(.easeOut(duration: 0.5), value: showBrowseShellRow)
          }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
      }
      VStack {
        HStack {
          if userSettings.automaticDirectoryPath.isEmpty {
            OutlineButton(title: "Later") {
              presentationMode.wrappedValue.dismiss()
            }
          }
          Spacer()
          BlueButton(title: "Done") {
            presentationMode.wrappedValue.dismiss()
          }
          .disabled(userSettings.automaticDirectoryPath.isEmpty)
          
        }
        .padding(10)
      }
    }
    .padding(2)
    .frame(width: 500, height: 320)
  }
  
  func checkForShellFileAndAnimate() {
    if !userSettings.automaticDirectoryPath.isEmpty {
      if !FileManager.default.fileExists(atPath: userSettings.webuiShellPath) {
        withAnimation {
          showBrowseShellRow = true
        }
      }
    }
  }
}


#Preview {
  RequiredInputPathsView()
    .frame(width: 500, height: 400)
}

struct BrowseRequiredFileRow: View {
  var labelText: String?
  var placeholderText: String
  @Binding var textValue: String
  var requiresEntry: Bool = false
  var browseAction: () async -> String?
  
  @State private var indicatorType: IndicatorType = .none
  
  private enum IndicatorType {
    case checkmark, xmark, none
    
    var imageName: String {
      switch self {
      case .checkmark:
        return "checkmark.circle.fill"
      case .xmark:
        return "xmark.circle.fill"
      case .none:
        return "square.dashed"
      }
    }
    
    var imageColor: Color {
      switch self {
      case .checkmark:
        return .green
      case .xmark:
        return .red
      case .none:
        return .clear
      }
    }
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        if requiresEntry || !textValue.isEmpty {
          Image(systemName: indicatorType.imageName)
            .foregroundColor(indicatorType.imageColor)
            .padding(.bottom, 2)
        }
        
        if let label = labelText {
          Text(label)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.bottom, 5)
        }
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
    .onChange(of: textValue) {
      updateIndicator(for: textValue)
    }
    .onAppear {
      updateIndicator(for: textValue)
    }
  }
  
  private func updateIndicator(for value: String) {
    if requiresEntry {
      indicatorType = value.isEmpty ? .xmark : .checkmark
    } else {
      indicatorType = .checkmark
    }
  }
}
