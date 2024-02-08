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
  @AppStorage("fileOutputDir") var fileOutputDir: String = ""
  
  @StateObject private var promptViewModel = PromptViewModel()
  @StateObject var modelManagerViewModel = ModelManagerViewModel()
  
  init() {
    setupAppFileStructure()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView(modelManagerViewModel: modelManagerViewModel, promptViewModel: promptViewModel, scriptManager: scriptManager, scriptPathInput: $scriptPathInput, fileOutputDir: $fileOutputDir)
        .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity,
               minHeight: 400, idealHeight: 600, maxHeight: .infinity)
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
}


// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    ScriptManager.shared.terminateImmediately()
    
    return .terminateNow
  }
}
