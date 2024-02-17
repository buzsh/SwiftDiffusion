//
//  FilesSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct FilesSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    BrowseFileRow(labelText: "Custom image output directory",
                  placeholderText: "~/Documents/SwiftDiffusion/",
                  textValue: $userSettings.outputDirectoryPath) {
      await FilePickerService.browseForDirectory()
    }
    
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
  }
}

#Preview {
  SettingsView(selectedTab: .files)
}
