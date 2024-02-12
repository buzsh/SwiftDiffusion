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
    
      HStack {
        Text(selectedTab.sectionHeaderText)
          .font(.title)
          .padding(.leading, 12)
          .padding(.bottom, 10)
          .padding(.top, 20)
        Spacer()
        
        if selectedTab.hasHelpIndicators {
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
      }
      .padding(.horizontal, 14)
      .padding(.top)

  }
  
}


#Preview("Prompt Tab") {
  SettingsView(selectedTab: .prompt)
}

#Preview("Files Tab") {
  SettingsView(selectedTab: .files)
}
