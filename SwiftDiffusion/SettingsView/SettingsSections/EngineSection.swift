//
//  EngineSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct EngineSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    VStack(alignment: .leading) {
      ToggleWithHeader(isToggled: $userSettings.disableModelLoadingRamOptimizations, header: "Disable model loading RAM optimizations", description: "Can sometimes resolve certain model load issues regarding MPS, BFloat16. Warning: Can increase load times significantly.", showAllDescriptions: userSettings.alwaysShowSettingsHelp)
      
    }
  }
}

#Preview {
  SettingsView(selectedTab: .engine)
}
