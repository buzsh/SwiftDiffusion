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
  
  var apiHasLoadedInitialCheckpointModel: String {
    if checkpointsManager.apiHasLoadedInitialCheckpointModel {
      return "true"
    }
    return "false"
  }
  
  var body: some View {
    if userSettings.showDeveloperInterface {
      VStack {
        HStack {
          Spacer()
          VStack(alignment: .leading) {
            Text("     ScriptState: \(scriptManager.scriptState.debugInfo)")
            Text("GenerationStatus: \(scriptManager.genStatus.debugInfo) (\(Int(scriptManager.genProgress * 100))%)")
            Text("  ModelLoadState: \(scriptManager.modelLoadState.debugInfo) (\(String(format: "%.1f", scriptManager.modelLoadTime))s)")
          }
          Spacer()
        }
        
        Divider().foregroundStyle(Color.white)
        
        HStack {
          Spacer()
          VStack(alignment: .leading) {
            Text("apiHasLoadedInitialCheckpointModel: \(apiHasLoadedInitialCheckpointModel)")
          }
          Spacer()
        }
      }
      .padding(.horizontal)
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(Color.white)
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
}


