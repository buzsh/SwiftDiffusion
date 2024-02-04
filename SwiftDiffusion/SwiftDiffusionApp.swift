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
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowToolbarStyle(DefaultWindowToolbarStyle())
  }
}



class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    ScriptManager.shared.terminateImmediately()
    
    return .terminateNow
  }
  
  func handleQuit() {
    ScriptManager.shared.terminateScript { result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          NSApp.terminate(nil)
        case .failure:
          let alert = NSAlert()
          alert.messageText = "Failed to terminate script. Do you still want to continue?"
          alert.informativeText = "Choosing 'Quit App' will force the application to quit."
          alert.addButton(withTitle: "Cancel")
          alert.addButton(withTitle: "Quit App")
          let response = alert.runModal()
          
          if response == .alertSecondButtonReturn {
            NSApp.terminate(nil)
          }
          // else, do nothing
        }
      }
    }
  }
}
