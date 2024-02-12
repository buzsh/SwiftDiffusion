//
//  PromptSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct PromptSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    VStack(alignment: .leading) {
      ToggleWithHeader(isToggled: $userSettings.disablePasteboardParsingForGenerationData, header: "Disable automatic generation data parsing", description: "When you copy generation data from sites like Civit.ai, this will automatically format it and show a button to paste it.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
      ToggleWithHeader(isToggled: $userSettings.alwaysShowPasteboardGenerationDataButton, header: "Always show Paste Generation Data button", description: "This will cause the 'Paste Generation Data' button to always show, even if copied data is incompatible and cannot be pasted.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
    }
  }
}

#Preview {
  SettingsView(userSettings: UserSettings.shared, selectedTab: .prompt)
}
