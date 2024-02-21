//
//  EngineSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct EngineSection: View {
  @ObservedObject var userSettings: UserSettings
  @ObservedObject var scriptManager = ScriptManager.shared
  
  @State var showRestartAppForChangesToTakeEffectAlert: Bool = false
  
  var body: some View {
    VStack(alignment: .leading) {
      ToggleWithHeader(isToggled: $userSettings.disableModelLoadingRamOptimizations, header: "Disable model loading RAM optimizations", description: "Can resolve certain model loading issues involving the MPS framework (TypeError: float16, float32, float64).\n\nNote: Can also increase model loading times.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
    }
    .onChange(of: userSettings.disableModelLoadingRamOptimizations) {
      showRestartAppForChangesToTakeEffectAlert = true
    }
    .alert(isPresented: $showRestartAppForChangesToTakeEffectAlert) {
      var message: String = ""
      message.append("SwiftDiffusion needs to be restarted in order for these changes to take effect.\n\nWould you like to close the app now?\n\nNote: Due to MacOS restrictions, you may need to re-open the app yourself.")
      
      return Alert(
        title: Text("App Restart Required"),
        message: Text(message),
        primaryButton: .default(Text("Close App")) {
          scriptManager.terminateImmediately()
          Delay.by(0.1) {
            relaunchApplication()
          }
          
        },
        secondaryButton: .cancel(Text("Later")) {
          Debug.log("User chose to postpone restart")
        }
      )
    }
  }
  
  func relaunchApplication() {
    let appRelauncher = AppRelauncherUtility()
    appRelauncher.relaunchApplication()
  }
}

#Preview {
  SettingsView(selectedTab: .engine)
}

