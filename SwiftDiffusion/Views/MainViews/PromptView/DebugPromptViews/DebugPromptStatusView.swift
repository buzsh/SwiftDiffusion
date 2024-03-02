//
//  DebugPromptStatusView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct DebugPromptStatusView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @ObservedObject var scriptManager = ScriptManager.shared
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  
  var body: some View {
    if userSettings.showDeveloperInterface {
      VStack(spacing: 0) {
        HStack {
          Spacer()
          VStack(alignment: .leading) {
            Text("     ScriptState: \(scriptManager.scriptState.debugInfo)")
            Text("GenerationStatus: \(scriptManager.genStatus.debugInfo) (\(Int(scriptManager.genProgress * 100))%)")
            Text("  ModelLoadState: \(scriptManager.modelLoadState.debugInfo) (\(String(format: "%.1f", scriptManager.modelLoadTime))s)")
          }
          Spacer()
        }
        
        Divider().padding(.top, 10)
        
        ApiCheckpointRow()
      }
      .padding(.horizontal)
      .padding(.vertical, 6)
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(Color.white)
      .background(Color.black)
    }
  }
}

#Preview {
  CommonPreviews.promptView
}

#Preview {
  DebugPromptStatusView(scriptManager: ScriptManager.preview(withState: .readyToStart))
}


