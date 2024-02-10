//
//  DebugPromptStatusView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptStatusView: View {
  @ObservedObject var scriptManager: ScriptManager
  @ObservedObject var userSettings: UserSettingsModel
  
  var body: some View {
    if userSettings.showDebugMenu {
      HStack {
        Spacer()
        VStack(alignment: .leading) {
          Text("     ScriptState: \(scriptManager.scriptState.debugInfo)")
          Text("GenerationStatus: \(scriptManager.genStatus.debugInfo) (\(Int(scriptManager.genProgress * 100))%)")
          Text("  ModelLoadState: \(scriptManager.modelLoadState.debugInfo) (\(String(format: "%.1f", scriptManager.modelLoadTime))s)")
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


