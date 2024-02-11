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
  @AppStorage("scriptPathInput") var scriptPathInput: String = ""
  
  let promptModel = PromptModel()
  let modelManangerViewModel = ModelManagerViewModel()
  
  init() {
    setupAppFileStructure()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView(scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
        .frame(minWidth: 600, idealWidth: 900, maxWidth: .infinity,
               minHeight: 400, idealHeight: 800, maxHeight: .infinity)
        .environmentObject(promptModel)
        .environmentObject(modelManangerViewModel)
    }
    .windowToolbarStyle(DefaultWindowToolbarStyle())
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
}
