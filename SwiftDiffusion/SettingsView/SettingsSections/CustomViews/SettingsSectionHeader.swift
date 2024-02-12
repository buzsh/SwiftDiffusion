//
//  SettingsSectionHeader.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct SettingsSectionHeader: View {
  @ObservedObject var userSettings: UserSettings
  var selectedTab: SettingsTab = .general
  
  var body: some View {
    if selectedTab.hasHelpIndicators {
      HStack {
        Text(selectedTab.sectionHeaderText)
          .font(.title2)
          .padding(.leading, 12)
          .padding(.bottom, 10)
          .padding(.top, 20)
        Spacer()
        
        Spacer()
        Button(action: {
          userSettings.alwaysShowSettingsHelp.toggle()
        }) {
          HStack {
            Text(userSettings.alwaysShowSettingsHelp ? "Hide Help" : "Always Show Help")
              .font(.system(size: 11))
          }
          .padding(.horizontal, 2)
        }
      }
      .padding(.horizontal, 14)
      .padding(.top)
    }
  }
  
}


#Preview("Prompt Tab") {
  SettingsView(userSettings: UserSettings.shared, selectedTab: .prompt)
}

#Preview("Files Tab") {
  SettingsView(userSettings: UserSettings.shared, selectedTab: .files)
}
