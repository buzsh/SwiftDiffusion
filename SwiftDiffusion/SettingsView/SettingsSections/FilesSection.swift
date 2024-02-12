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
    HStack {
      Text("Automatic Paths")
        .font(.title2)
        .padding(.leading, 12)
        .padding(.bottom, 10)
        .padding(.top, 20)
      Spacer()
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
    
    BrowseFileRow(labelText: "Custom image output directory",
                  placeholderText: "~/Documents/SwiftDiffusion/",
                  textValue: $userSettings.outputDirectoryPath) {
      await FilePickerService.browseForDirectory()
    }
  }
}

#Preview {
  SettingsView(selectedTab: .files)
}
