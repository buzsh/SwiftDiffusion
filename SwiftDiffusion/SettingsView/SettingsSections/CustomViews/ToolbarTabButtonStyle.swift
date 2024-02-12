//
//  ToolbarTabButtonStyle.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct ToolbarTabButtonStyle: ButtonStyle {
  var isSelected: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(isSelected ? Color.accentColor : Color.primary)
      .padding(4)
      .frame(minWidth: 56)
      .background(self.isSelected ? Color.gray.opacity(0.2) : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

#Preview {
  SettingsView(userSettings: UserSettings.shared, selectedTab: .general)
}
