//
//  FilesSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct FilesSection: View {
  @ObservedObject var userSettings: UserSettings
  @State private var isExpanded: Bool = false
  
  @State private var showingModifiedAutomaticPathAlert: Bool = false
  
  var body: some View {
    BrowseFileRow(labelText: "Generated image output directory",
                  placeholderText: "~/Documents/SwiftDiffusion/",
                  textValue: $userSettings.outputDirectoryPath) {
      await FilePickerService.browseForDirectory()
    }
    
    BrowseFileRow(labelText: "Automatic path directory",
                  placeholderText: "../stable-diffusion-webui/",
                  textValue: $userSettings.automaticDirectoryPath) {
      await FilePickerService.browseForDirectory()
    }
                  .onChange(of: userSettings.automaticDirectoryPath) { newPath, oldPath in
                    Debug.log("User set new automaticDirectoryPath: \(newPath) from oldPath: \(oldPath) ")
                    if oldPath.isEmpty {
                      userSettings.setDefaultPathsForEmptySettings()
                    } else if newPath != oldPath {
                      showingModifiedAutomaticPathAlert = true
                    }
                  }
                  .alert(isPresented: $showingModifiedAutomaticPathAlert) {
                    Alert(
                      title: Text("New Automatic location"),
                      message: Text("It looks like the path to your Automatic folder has changed. Would you like for \(Constants.App.name) to update your LoRA, VAE and other related directories for you as well?\n\nIf not, you'll need to set them manually yourself in the 'Custom Automatic Paths' section."),
                      primaryButton: .default(Text("Update For Me")) {
                        userSettings.resetDefaultPathsToEmpty()
                        userSettings.setDefaultPathsForEmptySettings()
                      },
                      secondaryButton: .cancel() {
                        isExpanded = true
                      }
                    )
                  }
    
    ExpandableSectionHeader(title: "Custom Automatic Paths", isExpanded: $isExpanded)
    
    if isExpanded {
      
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
      
      BrowseFileRow(labelText: "LoRA models path",
                    placeholderText: "../stable-diffusion-webui/models/Lora/",
                    textValue: $userSettings.loraDirectoryPath) {
        await FilePickerService.browseForDirectory()
      }
      
      BrowseFileRow(labelText: "VAE models path",
                    placeholderText: "../stable-diffusion-webui/models/VAE/",
                    textValue: $userSettings.vaeDirectoryPath) {
        await FilePickerService.browseForDirectory()
      }
    }
  }
}

#Preview {
  SettingsView(selectedTab: .files)
}
