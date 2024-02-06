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
  
  @StateObject private var mainViewModel = MainViewModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView(mainViewModel: mainViewModel, scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
        .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity,
               minHeight: 400, idealHeight: 600, maxHeight: .infinity)
    }
    .windowToolbarStyle(DefaultWindowToolbarStyle())
  }
}



class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    ScriptManager.shared.terminateImmediately()
    
    return .terminateNow
  }
  
}
