//
//  SwiftDiffusionApp.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

@main
struct SwiftDiffusionApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var scriptManager = ScriptManager.shared
  
  let currentPrompt = PromptModel()
  let modelManangerViewModel = ModelManagerViewModel()
  
  init() {
    setupAppFileStructure()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView(scriptManager: scriptManager)
        .frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity,
               minHeight: 500, idealHeight: 800, maxHeight: .infinity)
        .environmentObject(currentPrompt)
        .environmentObject(modelManangerViewModel)
    }
    .windowToolbarStyle(.unified(showsTitle: false))
    .commands {
      CommandGroup(after: .appInfo) {
        Divider()
        
        Button("Check for Updates...") {
          WindowManager.shared.showUpdatesWindow()
        }
        .keyboardShortcut("U", modifiers: [.command])
        
        Divider()
        
        Button("Settings...") {
          WindowManager.shared.showSettingsWindow()
        }
        .keyboardShortcut(",", modifiers: [.command])
      }
    }
    .commands {
      CommandMenu("Prompt") {
        Button("Copy Generation Data") {
          currentPrompt.copyMetadataToClipboard()
        }
      }
    }
  }
}
