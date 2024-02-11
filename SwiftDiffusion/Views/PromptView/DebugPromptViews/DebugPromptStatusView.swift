//
//  DebugPromptStatusView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptStatusView: View {
  @EnvironmentObject var userSettings: UserSettingsModel
  
  @ObservedObject var scriptManager: ScriptManager
  
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
  DebugPromptStatusView(scriptManager: ScriptManager.preview(withState: .readyToStart))
    .environmentObject(UserSettingsModel.preview())
}


