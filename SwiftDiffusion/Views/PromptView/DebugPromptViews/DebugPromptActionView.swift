//
//  DebugPromptActionView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptActionView: View {
  @ObservedObject var userSettings: UserSettingsModel
  var logPromptProperties: () -> Void
  
  var body: some View {
    if userSettings.showDebugMenu {
      HStack {
        Spacer()
        VStack(alignment: .leading) {
          Button("Log Prompt") {
            logPromptProperties()
          }
        }
        .padding(.horizontal)
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color.white)
        Spacer()
      }
      .padding(.vertical, 6).padding(.bottom, 2)
      .background(Color.black)
    }
  }
}


#Preview {
  CommonPreviews.promptView
}

#Preview {
  DebugPromptStatusView(scriptManager: ScriptManager.readyPreview(),
                        userSettings: UserSettingsModel.preview())
}
