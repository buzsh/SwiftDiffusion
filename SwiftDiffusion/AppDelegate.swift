//
//  AppDelegate.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    ScriptManager.shared.terminateImmediately()
    
    return .terminateNow
  }
  
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    Debug.log("applicationDidFinishLaunching")
  }
  
}
