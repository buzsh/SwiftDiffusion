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
      
      ToggleWithHeader(isToggled: $userSettings.showPythonEnvironmentControls, header: "Show Python environment controls", description: "This will allow you to build and stop the Python environment from the toolbar. Also comes with a little status light!", showAllDescriptions: userSettings.alwaysShowSettingsHelp).disabled(userSettings.showDeveloperInterface) 
      
      ToggleWithHeader(isToggled: $userSettings.showDeveloperInterface, header: "Show developer interface", description: "This will show the developer tools, live variable states and other debugging information.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
      ToggleWithHeader(isToggled: $userSettings.launchWebUiAlongsideScriptLaunch, header: "Launch webui with script", description: "This will cause the --nowebui command line argument to be excluded from the launch conditions. Useful for needing to debug in a web browser.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
      ToggleWithHeader(isToggled: $userSettings.killAllPythonProcessesOnTerminate, header: "Kill all Python processes on terminate", description: "Will terminate all Python processes on terminate. Useful for Xcode development force stopping.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
    }
  }
}

#Preview {
  SettingsView(selectedTab: .developer)
}
