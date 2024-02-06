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
  @StateObject private var mainViewModel = MainViewModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView(mainViewModel: mainViewModel, scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
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
