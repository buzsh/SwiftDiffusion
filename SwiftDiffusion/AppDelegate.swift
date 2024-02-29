//
//  AppDelegate.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  
  private var dragEventMonitor: DragEventMonitor?
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    dragEventMonitor = nil
    ScriptManager.shared.terminateImmediately()
    
    return .terminateNow
  }
  
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    Debug.log("applicationDidFinishLaunching")
    dragEventMonitor = DragEventMonitor()
    // TODO: Python PID tracker
    
    // NSUserDefaults Python PID
    
    // on launch, killall programs with PID saved to Defaults
    // for PIDs that were killed, remove from Defaults list
    
    // check all running programs for name with "Python" (except those in Defaults)
    // disinclude from the tracking list henceforth
    
    // on terminate, kill all tracked PIDs
  }
  
}

import Cocoa

class DragEventMonitor {
  private var dragMonitor: Any?
  
  init() {
    dragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { event in
      DragState.shared.isDragging = false
      return event
    }
  }
  
  deinit {
    if let dragMonitor = dragMonitor {
      NSEvent.removeMonitor(dragMonitor)
    }
  }
}
