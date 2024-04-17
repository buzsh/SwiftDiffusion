//
//  DeveloperToolbarItems.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

struct DeveloperToolbarItems: View {
  @Binding var selectedView: ViewManager
  @ObservedObject private var userSettings = UserSettings.shared
  @ObservedObject private var scriptManager = ScriptManager.shared
  @ObservedObject private var pastableService = PastableService.shared
  
  var body: some View {
    if userSettings.showDeveloperInterface || userSettings.showPythonEnvironmentControls  {
      if userSettings.showPythonEnvironmentControls {
        Circle()
          .fill(scriptManager.scriptState.statusColor)
          .frame(width: 10, height: 10)
          .padding(.trailing, 2)
      }
      
      if userSettings.showPythonEnvironmentControls && userSettings.launchWebUiAlongsideScriptLaunch {
        if scriptManager.scriptState == .active, let url = scriptManager.serviceUrl {
          
          ToolbarSymbolButton(title: "Network", symbol: .network, action: {
            NSWorkspace.shared.open(url)
          })
        }
      }
      
      if userSettings.showDeveloperInterface {
        SegmentedViewPicker(selectedView: $selectedView)
      }
      
      if userSettings.showPythonEnvironmentControls,
         let title = (scriptManager.scriptState == .readyToStart) ? "Start" : "Stop" {
        
        ToolbarSymbolButton(title: title, symbol: actionButtonSymbol, action: {
          scriptManager.scriptState == .readyToStart ? scriptManager.run() : scriptManager.terminate()
        })
        .disabled(scriptManager.scriptState == .terminated)
      }
    }
  }
  
  var actionButtonTitle: String {
    if scriptManager.scriptState == .readyToStart {
      "Start"
    } else {
      "Stop"
    }
  }
  
  var actionButtonSymbol: SFSymbol {
    if scriptManager.scriptState == .readyToStart {
      SFSymbol.play
    } else {
      SFSymbol.stop
    }
  }
  
}
