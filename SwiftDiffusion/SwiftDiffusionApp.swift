//
//  SwiftDiffusionApp.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Cocoa
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

// TODO: UI indicators for user on error
/// Initialize app file-folder structure setup with error handling.
func setupAppFileStructure() {
  AppFileStructure.setup { error, failedUrl in
    if let error = error, let failedUrl = failedUrl {
      Debug.log("Failed to create directory at \(failedUrl): \(error)")
    } else if let error = error {
      Debug.log("Error: \(error)")
    } else {
      Debug.log("Successfully initialized application file structure.")
    }
  }
  AppFileStructure.setupDocuments { error, failedUrl in
    if let error = error, let failedUrl = failedUrl {
      Debug.log("Failed to create directory at \(failedUrl): \(error)")
    } else if let error = error {
      Debug.log("Error: \(error)")
    } else {
      Debug.log("Successfully initialized application documents structure.")
    }
  }
}


// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    ScriptManager.shared.terminateImmediately()
    
    return .terminateNow
  }
  
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    Debug.log("applicationDidFinishLaunching")
  }
  
}
