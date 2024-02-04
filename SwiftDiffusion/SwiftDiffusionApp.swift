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
          // Proceed to quit the app
          NSApp.terminate(nil)
        case .failure:
          // Show an alert and ask the user if they still want to quit
          let alert = NSAlert()
          alert.messageText = "Failed to terminate script. Do you still want to continue?"
          alert.informativeText = "Choosing 'Quit App' will force the application to quit."
          alert.addButton(withTitle: "Cancel")
          alert.addButton(withTitle: "Quit App")
          let response = alert.runModal()
          
          if response == .alertSecondButtonReturn {
            // Force quit the app
            NSApp.terminate(nil)
          }
          // If the user cancels, do not quit the app; possibly reset the state or wait for further user action
        }
      }
    }
  }
}
