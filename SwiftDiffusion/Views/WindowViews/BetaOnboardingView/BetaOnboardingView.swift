//
//  WelcomeView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/2/24.
//

import SwiftUI

enum PyTorchInterface: String, CaseIterable, Identifiable {
  case automatic1111 = "Automatic1111"
  //case comfyUI = "ComfyUI"
  
  var id: String { self.rawValue }
  var description: String {
    switch self {
    case .automatic1111: "Hello"
      //case .comfyUI: "ComfyUI description"
    }
  }
}

struct BetaOnboardingView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @Environment(\.presentationMode) var presentationMode
  
  @State private var selectedInterface: PyTorchInterface = .automatic1111
  @State private var currentStep: Int = 1
  @State private var isMovingForward = true
  
  var body: some View {
    VStack {
      HStack {
        Button(action: {
          presentationMode.wrappedValue.dismiss()
        }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 20))
            .foregroundStyle(.secondary)
            .opacity(0.6)
        }
        .buttonStyle(.plain)
        .padding(.leading, 10)
        .padding(.top, 10)
        
        Spacer()
      }
      
      ScrollView {
        VStack(alignment: .leading, spacing: 6) {
          VStack(alignment: .center) {
            HStack {
              Spacer()
              Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300)
              Spacer()
            }
            Text("Welcome to the Preview Release!")
              .padding(.top, 8)
              .opacity(0.8)
          }
          .padding(.top, 10)
          .padding(.bottom, 40)
          
          HStack {
            Spacer()
            Group {
              if currentStep == 1 {
                SetupStepView(title: "Getting Started", subTitle: "Select the PyTorch interface that you'd like to use", selectedInterface: $selectedInterface)
              } else if currentStep == 2 {
                SetupTypeStepView(title: "Setup Automatic", subTitle: "Would you like to use an existing Automatic setup,\nor start a new one?", selectedInterface: $selectedInterface)
              } else if currentStep == 3 {
                ConfigPathStepView(title: "Locate Automatic Folder", subTitle: "Browse for the stable-diffusion-webui folder", selectedInterface: $selectedInterface)
              }
            }
            .transition(.opacity)
            Spacer()
          }
        }
        .padding(.horizontal, 20)
      }
      
      HStack {
        Button(action: {
          withAnimation {
            if currentStep > 1 {
              currentStep -= 1
            }
          }
        }) {
          Text("Back")
        }
        .buttonStyle(BlueBackgroundButtonStyle())
        .disabled(currentStep == 1)
        
        Spacer()
        
        Circle()
          .frame(width: 10, height: 10)
          .foregroundColor(currentStep == 1 ? .primary : .secondary.opacity(0.6))
        Circle()
          .frame(width: 10, height: 10)
          .foregroundColor(currentStep == 2 ? .primary : .secondary.opacity(0.6))
        Circle()
          .frame(width: 10, height: 10)
          .foregroundColor(currentStep == 3 ? .primary : .secondary.opacity(0.6))
        
        Spacer()
        
        Button(action: {
          withAnimation {
            if currentStep < 4 {
              currentStep += 1
            }
            if currentStep > 3 {
              presentationMode.wrappedValue.dismiss()
            }
          }
        }) {
          Text(currentStep == 3 ? "Done" : "Next")
        }
        .buttonStyle(BlueBackgroundButtonStyle())
        
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 12)
    }
    .frame(width: 500, height: 400)
    //.frame(minWidth: 400, idealWidth: 500, minHeight: 300, idealHeight: 400)
  }
}

#Preview {
  BetaOnboardingView()
}

struct CapsuleTextView: View {
  var text: String
  
  var body: some View {
    Text(text)
      .textCase(.lowercase)
      .foregroundColor(.white)
      .font(.system(size: 10, weight: .regular, design: .monospaced))
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(
        Capsule()
          .fill(Color.blue)
      )
  }
}

struct SetupStepView: View {
  let title: String
  let subTitle: String
  @Binding var selectedInterface: PyTorchInterface
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .padding(.bottom, 4)
      
      Text(subTitle)
        .padding(.bottom, 20)
      
      Picker("", selection: $selectedInterface) {
        ForEach(PyTorchInterface.allCases) { option in
          Text(option.rawValue).tag(option)
          HStack {
            Text("ComfyUI")
            CapsuleTextView(text: "Coming Soon")
              .opacity(0.6)
          }
          .padding(.vertical, 6)
        }
        .font(.system(size: 14, weight: .medium))
      }
      .pickerStyle(RadioGroupPickerStyle())
      .padding(.horizontal, 10)
    }
  }
}

struct SetupTypeStepView: View {
  let title: String
  let subTitle: String
  @Binding var selectedInterface: PyTorchInterface
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .padding(.bottom, 4)
      
      Text(subTitle)
        .padding(.bottom, 20)
      
      Picker("", selection: $selectedInterface) {
        ForEach(PyTorchInterface.allCases) { option in
          Text("Use existing Automatic setup").tag(option)
          HStack {
            Text("Start new Automatic setup")
            CapsuleTextView(text: "Coming Soon")
              .opacity(0.6)
          }
          .padding(.vertical, 6)
        }
        .font(.system(size: 14, weight: .medium))
      }
      .pickerStyle(RadioGroupPickerStyle())
      .padding(.horizontal, 10)
    }
  }
}

struct ConfigPathStepView: View {
  @ObservedObject var userSettings = UserSettings.shared
  
  let title: String
  let subTitle: String
  @Binding var selectedInterface: PyTorchInterface
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .padding(.bottom, 4)
      
      Text(subTitle)
        .padding(.bottom, 10)
      
      BrowseFileRow(labelText: "",
                    placeholderText: "../stable-diffusion-webui/",
                    textValue: $userSettings.automaticDirectoryPath) {
        await FilePickerService.browseForDirectory()
      }
                    .frame(width: 350)
                    .onChange(of: userSettings.automaticDirectoryPath) {
                      userSettings.setDefaultPathsForEmptySettings()
                    }
    }
  }
}


import SwiftUI

struct SetupBrowseFileRow: View {
  var labelText: String?
  var placeholderText: String
  @Binding var textValue: String
  var browseAction: () async -> String?
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        TextField(placeholderText, text: $textValue)
          .truncationMode(.middle)
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
    }
  }
}
