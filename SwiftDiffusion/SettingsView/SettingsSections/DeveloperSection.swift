//
//  DeveloperSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct DeveloperSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    VStack(alignment: .leading) {
      ToggleWithHeader(isToggled: $userSettings.alwaysStartPythonEnvironmentAtLaunch, header: "Start Python environment at launch", description: "This will automatically ready the Python environment such that you can start generating immediately.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
      ToggleWithHeader(isToggled: $userSettings.showDebugMenu, header: "Show Debug menu", description: "This will show the Debug menu in the top menu bar.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
      ToggleWithHeader(isToggled: $userSettings.killAllPythonProcessesOnTerminate, header: "Kill all Python processes on terminate", description: "Will terminate all Python processes on terminate. Useful for Xcode development force stopping.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
    }
  }
}

#Preview {
  SettingsView(selectedTab: .developer)
}
