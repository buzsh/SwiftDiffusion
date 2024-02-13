//
//  RequiredInputPathsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import SwiftUI

struct RequiredInputPathsView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  @Environment(\.presentationMode) var presentationMode
  
  private var buttonTitle: String {
    userSettings.webuiShellPath.isEmpty || userSettings.stableDiffusionModelsPath.isEmpty ? "Later" : "Done"
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack {
          VStack(alignment: .leading) {
            HStack {
              Text("Select Automatic Paths")
                .font(.largeTitle)
                .padding(.vertical, 20)
                .padding(.horizontal, 14)
              Spacer()
              
            }
            
            Text("To enable Automatic1111, please provide the webui.sh file, as well as the folder in which the stable diffusion models are located.")
              .padding(.horizontal, 14)
              .padding(.bottom, 30)
            
            BrowseRequiredFileRow(labelText: "webui.sh file",
                                  placeholderText: "../stable-diffusion-webui/webui.sh",
                                  textValue: $userSettings.webuiShellPath, requiresEntry: true) {
              await FilePickerService.browseForShellFile()
            }
            
            BrowseRequiredFileRow(labelText: "Stable diffusion models",
                                  placeholderText: "../stable-diffusion-webui/models/Stable-diffusion/",
                                  textValue: $userSettings.stableDiffusionModelsPath, requiresEntry: true) {
              await FilePickerService.browseForDirectory()
            }
            
          }
          .onChange(of: userSettings.stableDiffusionModelsPath) {
            Task {
              await modelManagerViewModel.loadModels()
            }
          }
          
        }
        .padding(.horizontal, 16)
      }//scrollview
      VStack {
        HStack {
          Spacer()
          
          Button(action: {
            presentationMode.wrappedValue.dismiss()
          }) {
            Text(buttonTitle)
          }
        }
        
        .padding(10)
      }
      .background(Color(NSColor.windowBackgroundColor))
    }
    .padding(2)
    .navigationTitle("Select Automatic Paths")
    .frame(minWidth: 500, idealWidth: 500, minHeight: 350, idealHeight: 400)
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
        return ""
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
        }
        
        if let label = labelText {
          Text(label)
            .font(.system(size: 14, weight: .semibold, design: .default))
            .underline()
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
    .onChange(of: textValue) { newValue, _ in
      updateIndicator(for: newValue)
    }
    .onAppear {
      // Initial update based on the initial value of textValue
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
