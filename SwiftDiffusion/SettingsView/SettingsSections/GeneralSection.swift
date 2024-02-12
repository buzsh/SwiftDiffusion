//
//  GeneralSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct GeneralSection: View {
  @ObservedObject var userSettings: UserSettings
  
  var body: some View {
    Text("Coming soon")
  }
}

#Preview {
  SettingsView(selectedTab: .general)
}
